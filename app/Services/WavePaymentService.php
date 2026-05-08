<?php

namespace App\Services;

use App\Models\Paiement;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class WavePaymentService
{
    private ?string $apiKey;
    private ?string $baseUrl;
    private ?string $webhookSecret;

    public function __construct()
    {
        $this->apiKey = \env('WAVE_API_KEY');
        $this->baseUrl = \env('WAVE_API_URL', 'https://api.wave.com/v1');
        $this->webhookSecret = \env('WAVE_WEBHOOK_SECRET');
    }

    public function createCheckoutSession(Paiement $paiement): array
    {
        if (empty($this->apiKey)) {
            return [
                'success' => false,
                'message' => 'Paiement Wave non configuré (WAVE_API_KEY manquant).',
            ];
        }

        $appUrl = rtrim((string) \config('app.url'), '/');
        if ($appUrl === '' || str_contains($appUrl, 'localhost') || str_contains($appUrl, '127.0.0.1')) {
            return [
                'success' => false,
                'message' => 'APP_URL doit être un domaine HTTPS public pour Wave.',
            ];
        }
        if (str_starts_with($appUrl, 'http://')) {
            $appUrl = 'https://' . substr($appUrl, 7);
        }

        $clientReference = 'ARTRESTO_PAIEMENT_' . $paiement->id . '_' . Str::lower(Str::random(8));
        $successUrl = $appUrl . '/api/paiements/wave/return?status=success&ref=' . urlencode($clientReference);
        $errorUrl = $appUrl . '/api/paiements/wave/return?status=cancel&ref=' . urlencode($clientReference);

        $payload = [
            'amount' => (float) $paiement->montant,
            'currency' => 'XOF',
            'success_url' => $successUrl,
            'error_url' => $errorUrl,
            'client_reference' => $clientReference,
        ];

        Log::info('Wave: création checkout session', [
            'paiement_id' => $paiement->id,
            'commande_id' => $paiement->commande_id,
            'amount' => (float) $paiement->montant,
            'api_url' => rtrim((string) $this->baseUrl, '/') . '/checkout/sessions',
        ]);

        try {
            $response = Http::timeout(30)
                ->withToken($this->apiKey)
                ->acceptJson()
                ->post(rtrim((string) $this->baseUrl, '/') . '/checkout/sessions', $payload);
        } catch (ConnectionException $e) {
            Log::error('Wave: connexion impossible', [
                'paiement_id' => $paiement->id,
                'error' => $e->getMessage(),
            ]);
            return [
                'success' => false,
                'message' => 'Impossible de joindre Wave. Réessaie dans quelques instants.',
            ];
        } catch (\Throwable $e) {
            Log::error('Wave: exception création checkout session', [
                'paiement_id' => $paiement->id,
                'error' => $e->getMessage(),
            ]);
            return [
                'success' => false,
                'message' => 'Erreur interne lors de l’initialisation Wave.',
            ];
        }

        if (!$response->successful()) {
            Log::error('Wave: erreur création checkout session', [
                'paiement_id' => $paiement->id,
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            $msg = 'Erreur Wave (status ' . $response->status() . ')';
            $json = null;
            try {
                $json = $response->json();
            } catch (\Throwable $e) {
            }
            if (is_array($json)) {
                $msg = $json['message'] ?? $json['detail'] ?? $msg;
            }
            return [
                'success' => false,
                'message' => $msg,
            ];
        }

        $data = $response->json();
        $waveId = is_array($data) ? ($data['id'] ?? $data['transaction_id'] ?? null) : null;
        $paymentUrl = is_array($data)
            ? ($data['wave_launch_url'] ?? $data['checkout_url'] ?? $data['payment_url'] ?? null)
            : null;

        if (!$paymentUrl) {
            return [
                'success' => false,
                'message' => 'Wave n’a pas renvoyé d’URL de paiement.',
            ];
        }

        $paiement->update([
            'transaction_id' => $waveId ?: $paiement->transaction_id,
            'notes' => trim((string) ($paiement->notes ?? '')) === ''
                ? ('wave_ref=' . $clientReference)
                : ($paiement->notes . "\n" . 'wave_ref=' . $clientReference),
        ]);

        return [
            'success' => true,
            'payment_url' => $paymentUrl,
            'wave_id' => $waveId,
            'client_reference' => $clientReference,
        ];
    }

    public function validateWebhookSignature(array $payload, ?string $waveSignature): bool
    {
        if (empty($this->webhookSecret) || empty($waveSignature)) {
            return false;
        }

        if (!preg_match('/t=(\d+),v1=([a-f0-9]+)/', $waveSignature, $matches)) {
            return false;
        }

        $timestamp = $matches[1];
        $signature = $matches[2];

        $requestTime = (int) $timestamp;
        $currentTime = time();
        if (abs($currentTime - $requestTime) > 300) {
            return false;
        }

        $payloadJson = json_encode($payload, JSON_UNESCAPED_SLASHES);
        $signedPayload = $timestamp . '.' . $payloadJson;
        $expectedSignature = hash_hmac('sha256', $signedPayload, $this->webhookSecret);

        return hash_equals($expectedSignature, $signature);
    }

    public function parsePaiementIdFromClientReference(?string $clientReference): ?int
    {
        if (!$clientReference) return null;
        if (!str_starts_with($clientReference, 'ARTRESTO_PAIEMENT_')) return null;
        $rest = substr($clientReference, strlen('ARTRESTO_PAIEMENT_'));
        $parts = explode('_', $rest);
        if (!isset($parts[0]) || !is_numeric($parts[0])) return null;
        return (int) $parts[0];
    }
}
