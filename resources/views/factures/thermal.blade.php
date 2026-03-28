<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ticket #{{ $facture->numero_facture }}</title>
    <style>
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
        }
        body {
            font-family: DejaVu Sans, sans-serif;
            font-size: 10px;
            width: 100%;
            margin: 0;
            padding: 3mm 1.5mm 4mm 1.5mm;
            line-height: 1.25;
            color: #000;
            text-align: left;
        }
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        .bold { font-weight: bold; }
        .logo {
            max-width: 100%;
            height: auto;
            margin-bottom: 3mm;
        }
        .divider {
            border-top: 1px dashed #000;
            margin: 2mm 0;
        }
        .resto-name { font-size: 14px; margin-bottom: 1mm; }

        /* Tableaux : DomPDF gère mal flex ; largeurs % stables sur 80mm */
        table.ticket-table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            font-size: 9px;
        }
        table.ticket-table th,
        table.ticket-table td {
            padding: 0.5mm 0;
            vertical-align: top;
            word-wrap: break-word;
            overflow-wrap: break-word;
        }
        table.ticket-table .col-article {
            width: 46%;
            text-align: left;
            padding-right: 1mm;
        }
        table.ticket-table .col-qte {
            width: 14%;
            text-align: center;
            white-space: nowrap;
        }
        table.ticket-table .col-total {
            width: 40%;
            text-align: right;
            padding-left: 1mm;
            white-space: nowrap;
        }
        table.totals-table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            font-size: 10px;
            margin-top: 2mm;
        }
        table.totals-table td {
            padding: 0.5mm 0;
            vertical-align: top;
        }
        table.totals-table .label {
            width: 42%;
        }
        table.totals-table .amount {
            width: 58%;
            text-align: right;
            white-space: nowrap;
        }
        .footer { margin-top: 5mm; font-size: 8px; }
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
    <div class="text-center">{{ $facture->created_at->format('d/m/Y H:i') }}</div>

    @if(isset($table))
    <div class="text-center bold" style="margin-top: 1.5mm;">TABLE: {{ $table->numero }}</div>
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
    <div style="margin-top: 2mm; font-size: 9px;">
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

    <div class="footer text-center">
        <div class="bold">MERCI DE VOTRE VISITE !</div>
        <div>À bientôt !</div>
        <div style="margin-top: 1.5mm;">{{ now()->format('d/m/Y H:i:s') }}</div>
    </div>
</body>
</html>
