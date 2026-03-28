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
        html {
            margin: 0;
            padding: 0;
        }
        body {
            font-family: 'Courier', monospace; /* Police plus "ticket de caisse" */
            font-size: 12px;
            box-sizing: border-box;
            width: 100%;
            max-width: 100%;
            margin: 0;
            margin-left: 0;
            margin-right: 0;
            padding: 5mm 3mm 5mm 2mm;
            line-height: 1.2;
            color: #000;
            text-align: left;
        }
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        .bold { font-weight: bold; }
        .logo {
            max-width: 50mm;
            margin-bottom: 5mm;
        }
        .divider {
            border-top: 1px dashed #000;
            margin: 3mm 0;
        }
        .header { margin-bottom: 5mm; }
        .resto-name { font-size: 18px; margin-bottom: 2mm; }
        .item-row { display: flex; justify-content: space-between; margin-bottom: 1mm; }
        .item-name { flex: 2; }
        .item-qty { flex: 0.5; text-align: center; }
        .item-total { flex: 1.5; text-align: right; }
        .totals { margin-top: 5mm; }
        .total-row { display: flex; justify-content: space-between; font-size: 14px; }
        .footer { margin-top: 8mm; font-size: 10px; }
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

    <div class="text-center bold" style="font-size: 14px;">TICKET DE CAISSE</div>
    <div class="text-center">N° {{ $facture->numero_facture }}</div>
    <div class="text-center">{{ $facture->created_at->format('d/m/Y H:i') }}</div>

    @if(isset($table))
    <div class="text-center bold" style="margin-top: 2mm;">TABLE: {{ $table->numero }}</div>
    @endif

    <div class="divider"></div>

    <div class="bold">
        <div style="display: flex;">
            <div style="flex: 2;">ARTICLE</div>
            <div style="flex: 0.5; text-align: center;">QTÉ</div>
            <div style="flex: 1.5; text-align: right;">TOTAL</div>
        </div>
    </div>
    
    <div class="divider"></div>

    @foreach($products as $product)
    <div class="item-row">
        <div class="item-name">{{ $product->nom }}</div>
        <div class="item-qty">x{{ $product->pivot->quantite }}</div>
        <div class="item-total">{{ number_format($product->pivot->quantite * $product->pivot->prix_unitaire, 0, ',', ' ') }}</div>
    </div>
    @endforeach

    <div class="divider"></div>

    <div class="totals">
        <div class="total-row bold">
            <div>TOTAL</div>
            <div>{{ number_format($facture->montant_total, 0, ',', ' ') }} FCFA</div>
        </div>
        
        @if(isset($paiement))
        <div style="margin-top: 2mm;">
            <div>Payé par: {{ $paiement->moyen_paiement->displayName() }}</div>
            @if($paiement->moyen_paiement->value === 'especes')
                <div>Reçu: {{ number_format($paiement->montant_recu, 0, ',', ' ') }}</div>
                <div>Rendu: {{ number_format($paiement->monnaie_rendue, 0, ',', ' ') }}</div>
            @endif
        </div>
        @endif
    </div>

    <div class="footer text-center">
        <div class="bold">MERCI DE VOTRE VISITE !</div>
        <div>À bientôt !</div>
        <div style="margin-top: 2mm;">{{ now()->format('d/m/Y H:i:s') }}</div>
    </div>
</body>
</html>
