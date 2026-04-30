<?php

namespace App\Services;

use App\Models\Commande;
use App\Models\Facture;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Illuminate\Support\Facades\Log;

class FCMService
{
    protected $messaging;

    public function __construct(Messaging $messaging)
    {
        $this->messaging = $messaging;
    }

    /**
     * Envoyer une notification à une liste de tokens
     *
     * @param array $tokens Liste des tokens FCM
     * @param string $title Titre de la notification
     * @param string $body Corps de la notification
     * @param array $data Données supplémentaires (optionnel)
     * @return array Résultat de l'envoi
     */
    public function sendToTokens(array $tokens, string $title, string $body, array $data = [])
    {
        if (empty($tokens)) {
            return ['success' => 0, 'failure' => 0];
        }

        $notification = Notification::create($title, $body);

        // Canal + son alignés sur l’app : res/raw/notification_sound.mp3 (Android)
        // et notification_sound.mp3 dans le bundle iOS.
        $message = CloudMessage::new()
            ->withNotification($notification)
            ->withData($data)
            ->withAndroidConfig([
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'artrestaurant_order_channel',
                    'sound' => 'notification_sound',
                ],
            ])
            ->withApnsConfig([
                'payload' => [
                    'aps' => [
                        'sound' => 'notification_sound.mp3',
                    ],
                ],
            ]);

        $report = $this->messaging->sendMulticast($message, $tokens);

        Log::info('FCM Notification sent', [
            'success' => $report->successes()->count(),
            'failure' => $report->failures()->count(),
            'tokens_count' => count($tokens)
        ]);

        return [
            'success' => $report->successes()->count(),
            'failure' => $report->failures()->count(),
            'failures' => $report->failures(),
        ];
    }

    /**
     * Envoyer une notification à un topic
     *
     * @param string $topic Nom du topic
     * @param string $title Titre de la notification
     * @param string $body Corps de la notification
     * @param array $data Données supplémentaires (optionnel)
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = [])
    {
        $notification = Notification::create($title, $body);

        $message = CloudMessage::withTarget('topic', $topic)
            ->withNotification($notification)
            ->withData($data)
            ->withAndroidConfig([
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'artrestaurant_order_channel',
                    'sound' => 'notification_sound',
                ],
            ])
            ->withApnsConfig([
                'payload' => [
                    'aps' => [
                        'sound' => 'notification_sound.mp3',
                    ],
                ],
            ]);

        try {
            $this->messaging->send($message);
            Log::info("FCM Notification sent to topic: $topic");
            return true;
        } catch (\Throwable $e) {
            Log::error("FCM Topic Error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Notifier le client que son paiement a été validé (reçu + note de satisfaction).
     * À appeler après enregistrement d'un paiement (caisse web ou API).
     */
    public function notifyClientPaymentValidated(Commande $commande, Facture $facture): void
    {
        $client = $commande->user;

        if (!$client || empty($client->fcm_token)) {
            Log::info('FCM payment_validated: pas de client ou token FCM manquant', [
                'commande_id' => $commande->id,
                'user_id' => $commande->user_id,
            ]);
            return;
        }

        $title = 'Paiement validé';
        $body = 'Votre paiement a été enregistré. Facture ' . $facture->numero_facture . '. Consultez votre reçu et notez votre satisfaction.';

        $this->sendToTokens([$client->fcm_token], $title, $body, [
            'type' => 'payment_validated',
            'commande_id' => (string) $commande->id,
            'order_id' => (string) $commande->id,
            'facture_id' => (string) $facture->id,
            'numero_facture' => (string) $facture->numero_facture,
            'montant_total' => (string) $facture->montant_total,
        ]);
    }
}
