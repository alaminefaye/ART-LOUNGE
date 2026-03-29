<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ticket #{{ $facture->numero_facture }}</title>
    <style>
        /*
         * Ticket 80 mm — DomPDF + impression navigateur :
         * Le corps doit occuper 100 % de la zone @page (pas de max-width + margin:auto,
         * sinon le rendu PDF / aperçu Chrome peut rétrécir tout le bloc en « bande » à gauche).
         */
        @page {
            size: 80mm auto;
            margin: 0;
        }
        * {
            box-sizing: border-box;
        }
        html {
            margin: 0;
            padding: 0;
            width: 80mm;
        }
        body {
            font-family: DejaVu Sans, sans-serif;
            font-size: 9px;
            width: 80mm;
            max-width: none;
            margin: 0;
            padding: 2mm 2.5mm;
            line-height: 1.35;
            color: #000;
            text-align: left;
        }
        img {
            max-width: 100%;
            height: auto;
        }
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        .bold { font-weight: bold; }
        .logo {
            display: block;
            max-width: 100%;
            max-height: 18mm;
            width: auto;
            height: auto;
            margin: 0 auto 2mm;
        }
        .divider {
            border-top: 1px dashed #000;
            margin: 1.5mm 0;
        }
        .resto-name {
            font-size: 12px;
            margin-bottom: 1mm;
            word-wrap: break-word;
        }
        .header {
            max-width: 100%;
            word-wrap: break-word;
        }

        /* Tableaux : colonnes resserrées ; pas de nowrap sur les montants (retour à la ligne si besoin) */
        table.ticket-table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            font-size: 8px;
        }
        table.ticket-table th,
        table.ticket-table td {
            padding: 0.4mm 0;
            vertical-align: top;
            word-wrap: break-word;
        }
        table.ticket-table .col-article {
            width: 52%;
            text-align: left;
            padding-right: 0.5mm;
        }
        table.ticket-table .col-qte {
            width: 13%;
            text-align: center;
        }
        table.ticket-table .col-total {
            width: 35%;
            text-align: right;
            padding-left: 0.5mm;
            font-size: 8px;
        }
        table.totals-table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            font-size: 9px;
            margin-top: 2mm;
        }
        table.totals-table td {
            padding: 0.4mm 0;
            vertical-align: top;
            word-wrap: break-word;
        }
        table.totals-table .label {
            width: 38%;
        }
        table.totals-table .amount {
            width: 62%;
            text-align: right;
            font-size: 9px;
        }
        .payment-block {
            margin-top: 2mm;
            font-size: 8px;
            max-width: 100%;
            word-wrap: break-word;
        }
        .payment-block div {
            margin-bottom: 0.5mm;
        }
        .client-block {
            margin-top: 1.5mm;
            font-size: 8px;
            word-wrap: break-word;
        }
        .client-block .client-title {
            font-weight: bold;
            margin-bottom: 0.5mm;
        }
        .caissier-line {
            margin-top: 2mm;
            font-size: 8px;
            text-align: center;
            word-wrap: break-word;
        }
        .footer { margin-top: 4mm; font-size: 8px; }
    </style>
</head>
<body>
    <div class="header text-center">
        @if(isset($logo_base64) && $logo_base64)
            <img src="{{ $logo_base64 }}" class="logo" alt="Logo">
        @endif
        <div class="resto-name bold">{{ $restaurant['nom'] }}</div>
        <div>{{ $restaurant['adresse'] }}</div>
        <div>Tél: {{ $restaurant['telephone'] }}</div>
    </div>

    <div class="divider"></div>

    <div class="text-center bold" style="font-size: 11px;">TICKET DE CAISSE</div>
    <div class="text-center">N° {{ $facture->numero_facture }}</div>
    <div class="text-center">{{ ($facture->created_at ?? $commande->created_at ?? $paiement?->created_at ?? now())->format('d/m/Y H:i') }}</div>

    @if(isset($table))
    <div class="text-center bold" style="margin-top: 1.5mm;">TABLE: {{ $table->numero }}</div>
    @endif

    @if(!empty($client_display))
    <div class="client-block text-center">
        <div class="client-title">Client</div>
        <div>{{ $client_display['nom_complet'] }}</div>
        @if(!empty($client_display['telephone']))
            <div>Tél. {{ $client_display['telephone'] }}</div>
        @endif
    </div>
    @endif

    <div class="divider"></div>

    <table class="ticket-table" cellspacing="0" cellpadding="0">
        <thead>
            <tr class="bold">
                <th class="col-article">ARTICLE</th>
                <th class="col-qte">QTÉ</th>
                <th class="col-total">TOTAL</th>
            </tr>
        </thead>
        <tbody>
            @foreach($products as $product)
            <tr>
                <td class="col-article">{{ $product->nom }}</td>
                <td class="col-qte">x{{ $product->pivot->quantite }}</td>
                <td class="col-total">{{ number_format((float) ($product->pivot->quantite * $product->pivot->prix_unitaire), 0, ',', ' ') }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="divider"></div>

    <table class="totals-table bold" cellspacing="0" cellpadding="0">
        <tr>
            <td class="label">TOTAL</td>
            <td class="amount">{{ number_format((float) $facture->montant_total, 0, ',', ' ') }} FCFA</td>
        </tr>
    </table>

    @if(isset($paiement))
    <div class="payment-block">
        <div>Payé par : {{ $paiement->moyen_paiement->displayName() }}</div>
        @if($paiement->moyen_paiement->value === 'especes')
            @if($paiement->montant_recu !== null)
                <div><strong>Montant reçu :</strong> {{ number_format((float) $paiement->montant_recu, 0, ',', ' ') }} FCFA</div>
            @endif
            @php
                $aRendre = $paiement->monnaie_rendue;
                if ($aRendre === null && $paiement->montant_recu !== null) {
                    $aRendre = max(0, (float) $paiement->montant_recu - (float) $paiement->montant);
                }
            @endphp
            @if($aRendre !== null)
                <div><strong>Montant à rendre :</strong> {{ number_format((float) $aRendre, 0, ',', ' ') }} FCFA</div>
            @endif
        @endif
    </div>
    @endif

    @if(!empty($caissier_name))
    <div class="caissier-line">Encaissé par : {{ $caissier_name }}</div>
    @endif

    <div class="footer text-center">
        <div class="bold">MERCI DE VOTRE VISITE !</div>
        <div>À bientôt !</div>
        <div style="margin-top: 1.5mm;">{{ now()->format('d/m/Y H:i:s') }}</div>
    </div>
</body>
</html>
