<?php

namespace App\Services;

use App\Models\Commande;
use App\Models\Paiement;
use App\Models\Facture;
use Illuminate\Support\Facades\Storage;
use Barryvdh\DomPDF\Facade\Pdf;

class FactureService
{
    /**
     * Génère une facture pour une commande et un paiement
     */
    public function genererFacture(Commande $commande, Paiement $paiement): Facture
    {
        // Générer le numéro de facture unique
        $numeroFacture = Facture::genererNumeroFacture();

        // Créer la facture
        $facture = Facture::create([
            'commande_id' => $commande->id,
            'paiement_id' => $paiement->id,
            'numero_facture' => $numeroFacture,
            'montant_total' => $commande->montant_total,
            'montant_taxe' => 0, // À calculer si TVA applicable
        ]);

        // Générer le PDF
        $pdfPath = $this->genererPDF($facture);
        $facture->fichier_pdf = $pdfPath;
        $facture->save();

        return $facture;
    }

    /**
     * Génère le fichier PDF de la facture
     */
    private function genererPDF(Facture $facture): string
    {
        // Charger la facture avec toutes ses relations
        $facture->load(['commande.table', 'commande.produits', 'commande.user', 'paiement']);

        // Préparer le logo
        $logoPath = public_path('assets/img/logo.png');
        $logoBase64 = null;
        if (file_exists($logoPath)) {
            $logoData = file_get_contents($logoPath);
            $logoBase64 = 'data:image/' . pathinfo($logoPath, PATHINFO_EXTENSION) . ';base64,' . base64_encode($logoData);
        }

        // Préparer les données pour le PDF
        $data = [
            'facture' => $facture,
            'commande' => $facture->commande,
            'table' => $facture->commande->table,
            'products' => $facture->commande->produits, // Alias pour la vue
            'paiement' => $facture->paiement,
            'logo_base64' => $logoBase64,
            'restaurant' => [
                'nom' => config('app.name', 'Restaurant'),
                'adresse' => 'Nimbo ond point de la source',
                'telephone' => '0708792031',
                'email' => 'contact@resto.sn', // À configurer
            ],
        ];

        // Générer le PDF avec une vue
        $pdf = Pdf::loadView('factures.template', $data);

        // Définir le chemin de sauvegarde
        $fileName = "facture-{$facture->numero_facture}.pdf";
        $path = "factures/{$fileName}";

        // Sauvegarder le PDF dans le disque public
        Storage::disk('public')->put($path, $pdf->output());

        // Retourner le chemin relatif au storage (sans "public/")
        return $path;
    }

    /**
     * Télécharge une facture
     */
    public function telechargerFacture(Facture $facture): \Symfony\Component\HttpFoundation\BinaryFileResponse
    {
        $filePath = Storage::disk('public')->path($facture->fichier_pdf);
        
        if (!file_exists($filePath)) {
            throw new \Exception("Le fichier PDF de la facture n'existe pas.");
        }
        
        return response()->download($filePath, "facture-{$facture->numero_facture}.pdf");
    }

    /**
     * Régénère le PDF d'une facture existante
     */
    public function regenererPDF(Facture $facture): Facture
    {
        // Supprimer l'ancien PDF si existe
        if ($facture->fichier_pdf && Storage::disk('public')->exists($facture->fichier_pdf)) {
            Storage::disk('public')->delete($facture->fichier_pdf);
        }

        // Générer un nouveau PDF
        $pdfPath = $this->genererPDF($facture);
        $facture->fichier_pdf = $pdfPath;
        $facture->save();

        return $facture;
    }

    /**
     * Génère un flux PDF pour une commande ou une facture (Aperçu/Impression)
     */
    public function genererPDFApercu(Commande $commande): \Barryvdh\DomPDF\PDF
    {
        // Charger les relations
        $commande->load(['table', 'produits', 'user', 'paiements.facture']);
        
        // Trouver la facture si elle existe
        $facture = $commande->facture;
        $paiement = $commande->paiements()->where('statut', \App\Enums\StatutPaiement::Valide)->latest()->first();

        // Si pas de facture officielle, on crée un objet temporaire pour la vue
        if (!$facture) {
            $facture = new Facture([
                'numero_facture' => 'PROFORMA-' . $commande->id,
                'montant_total' => $commande->montant_total,
                'montant_taxe' => 0,
                'created_at' => now(),
            ]);
        }

        // Préparer le logo
        $logoPath = public_path('assets/img/logo.png');
        $logoBase64 = null;
        if (file_exists($logoPath)) {
            $logoData = file_get_contents($logoPath);
            $logoBase64 = 'data:image/' . pathinfo($logoPath, PATHINFO_EXTENSION) . ';base64,' . base64_encode($logoData);
        }

        $data = [
            'facture' => $facture,
            'commande' => $commande,
            'table' => $commande->table,
            'products' => $commande->produits,
            'paiement' => $paiement,
            'logo_base64' => $logoBase64,
            'restaurant' => [
                'nom' => config('app.name', 'Restaurant'),
                'adresse' => 'Nimbo ond point de la source',
                'telephone' => '0708792031',
                'email' => 'contact@resto.sn',
            ],
        ];

        return Pdf::loadView('factures.template', $data);
    }

    /**
     * Génère un flux PDF optimisé pour les imprimantes thermiques 80mm
     */
    public function genererPDFThermal(Commande $commande): \Barryvdh\DomPDF\PDF
    {
        // Charger les relations (client + user du paiement pour ticket caisse)
        $commande->load(['table', 'produits', 'user', 'client', 'paiements.facture']);

        $facture = $commande->facture;
        $paiement = $commande->paiements()->where('statut', \App\Enums\StatutPaiement::Valide)->latest()->first();
        $paiement?->loadMissing('user');

        if (!$facture) {
            $facture = new Facture([
                'numero_facture' => '80-' . $commande->id,
                'montant_total' => $commande->montant_total,
                'montant_taxe' => 0,
                'created_at' => now(),
            ]);
        }

        $logoPath = public_path('assets/img/logo.png');
        $logoBase64 = null;
        if (file_exists($logoPath)) {
            $logoData = file_get_contents($logoPath);
            $logoBase64 = 'data:image/' . pathinfo($logoPath, PATHINFO_EXTENSION) . ';base64,' . base64_encode($logoData);
        }

        $caissierName = $paiement?->user?->name;

        $clientDisplay = null;
        if ($commande->user && $commande->user->hasRole('client')) {
            $commande->loadMissing('client');
            $commande->user->loadMissing('client');
            $profil = $commande->client ?? $commande->user->client;
            if ($profil) {
                $clientDisplay = [
                    'nom_complet' => trim($profil->nom_complet),
                    'telephone' => $profil->telephone ? (string) $profil->telephone : '',
                ];
            } else {
                $clientDisplay = [
                    'nom_complet' => (string) $commande->user->name,
                    'telephone' => $commande->user->phone ? (string) $commande->user->phone : '',
                ];
            }
        }

        $data = [
            'facture' => $facture,
            'commande' => $commande,
            'table' => $commande->table,
            'products' => $commande->produits,
            'paiement' => $paiement,
            'caissier_name' => $caissierName,
            'client_display' => $clientDisplay,
            'logo_base64' => $logoBase64,
            'restaurant' => [
                'nom' => config('app.name', 'Restaurant'),
                'adresse' => 'Nimbo ond point de la source',
                'telephone' => '0708792031',
                'email' => 'contact@resto.sn',
            ],
        ];

        // Page 80 mm de large (points PostScript) : ticket aligné à gauche, pas centré sur du A4
        $mmToPt = static fn (float $mm): float => $mm * 72 / 25.4;

        return Pdf::loadView('factures.thermal', $data)
            ->setPaper([0, 0, $mmToPt(80), $mmToPt(297)], 'portrait')
            ->setOption('dpi', 96)
            ->setOption('defaultFont', 'DejaVu Sans')
            ->setOption('isHtml5ParserEnabled', true);
    }
}

