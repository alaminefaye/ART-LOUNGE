<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Facture {{ $facture->numero_facture }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'DejaVu Sans', Arial, sans-serif;
            font-size: 12px;
            color: #333;
            line-height: 1.6;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            display: table;
            width: 100%;
            margin-bottom: 30px;
            border-bottom: 3px solid #2c3e50;
            padding-bottom: 20px;
        }
        
        .header-left {
            display: table-cell;
            width: 60%;
        }
        
        .header-right {
            display: table-cell;
            width: 40%;
            text-align: right;
        }
        
        .resto-name {
            font-size: 24px;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        
        .resto-info {
            font-size: 11px;
            color: #666;
        }
        
        .facture-title {
            font-size: 20px;
            font-weight: bold;
            color: #e74c3c;
            margin-bottom: 5px;
        }
        
        .facture-numero {
            font-size: 14px;
            color: #666;
        }
        
        .info-section {
            display: table;
            width: 100%;
            margin-bottom: 30px;
        }
        
        .info-left {
            display: table-cell;
            width: 50%;
        }
        
        .info-right {
            display: table-cell;
            width: 50%;
            text-align: right;
        }
        
        .info-box {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        
        .info-label {
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        
        .table-section {
            margin-bottom: 30px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        thead {
            background: #2c3e50;
            color: white;
        }
        
        th {
            padding: 12px;
            text-align: left;
            font-weight: bold;
        }
        
        td {
            padding: 10px 12px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        .text-right {
            text-align: right;
        }
        
        .text-center {
            text-align: center;
        }
        
        .totals {
            margin-top: 20px;
            float: right;
            width: 300px;
        }
        
        .total-row {
            display: table;
            width: 100%;
            padding: 10px 0;
        }
        
        .total-label {
            display: table-cell;
            font-weight: bold;
            text-align: right;
            padding-right: 20px;
        }
        
        .total-value {
            display: table-cell;
            text-align: right;
            width: 120px;
        }
        
        .total-final {
            background: #2c3e50;
            color: white;
            padding: 15px;
            font-size: 16px;
            font-weight: bold;
            border-radius: 5px;
            margin-top: 10px;
        }
        
        .paiement-section {
            clear: both;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #e0e0e0;
        }
        
        .paiement-info {
            background: #e8f5e9;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #4caf50;
        }
        
        .footer {
            margin-top: 50px;
            padding-top: 20px;
            border-top: 2px solid #e0e0e0;
            text-align: center;
            font-size: 11px;
            color: #666;
        }
        
        .thank-you {
            font-size: 16px;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 10px;
        }
        
        .badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 10px;
            font-weight: bold;
        }
        
        .badge-especes {
            background: #4caf50;
            color: white;
        }
        
        .badge-wave {
            background: #ff6b6b;
            color: white;
        }
        
        .badge-orange {
            background: #ff9800;
            color: white;
        }
        
        .badge-carte {
            background: #2196f3;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- En-tête -->
        <div class="header">
            <div class="header-left">
                <div class="resto-name">{{ $restaurant['nom'] }}</div>
                <div class="resto-info">
                    📍 {{ $restaurant['adresse'] }}<br>
                    📞 {{ $restaurant['telephone'] }}<br>
                    📧 {{ $restaurant['email'] }}
                </div>
            </div>
            <div class="header-right">
                <div class="facture-title">FACTURE</div>
                <div class="facture-numero">N° {{ $facture->numero_facture }}</div>
                <div class="facture-numero">{{ $facture->created_at->format('d/m/Y H:i') }}</div>
            </div>
        </div>

        <!-- Informations -->
        <div class="info-section">
            <div class="info-left">
                <div class="info-box">
                    <div class="info-label">🪑 Table</div>
                    <div style="font-size: 18px; font-weight: bold; color: #e74c3c;">
                        {{ $table->numero }}
                    </div>
                    <div style="font-size: 11px; color: #666;">
                        Type: {{ ucfirst($table->type->value) }} | 
                        Capacité: {{ $table->capacite }} personnes
                    </div>
                </div>
            </div>
            <div class="info-right">
                <div class="info-box">
                    <div class="info-label">👤 Serveur/Caissier</div>
                    <div>{{ $commande->user->name ?? 'N/A' }}</div>
                </div>
            </div>
        </div>

        <!-- Détails de la commande -->
        <div class="table-section">
            <h3 style="margin-bottom: 15px; color: #2c3e50;">Détails de la commande</h3>
            <table>
                <thead>
                    <tr>
                        <th style="width: 50%;">Produit</th>
                        <th class="text-center" style="width: 15%;">Quantité</th>
                        <th class="text-right" style="width: 20%;">Prix Unit.</th>
                        <th class="text-right" style="width: 15%;">Total</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($products as $product)
                    <tr>
                        <td>
                            <strong>{{ $product->name }}</strong>
                            @if($product->pivot->notes)
                                <br><span style="font-size: 10px; color: #666;">Note: {{ $product->pivot->notes }}</span>
                            @endif
                        </td>
                        <td class="text-center">{{ $product->pivot->quantity }}</td>
                        <td class="text-right">{{ number_format($product->pivot->unit_price, 0, ',', ' ') }} FCFA</td>
                        <td class="text-right">
                            <strong>{{ number_format($product->pivot->quantity * $product->pivot->unit_price, 0, ',', ' ') }} FCFA</strong>
                        </td>
                    </tr>
                    @endforeach

                    @if($table->type->value === 'espace_jeux')
                    <tr>
                        <td>
                            <strong>Frais de salle (Occupation)</strong>
                            <br><span style="font-size: 10px; color: #666;">Table: {{ $table->numero }}</span>
                        </td>
                        <td class="text-center">{{ $commande->getDureeOccupationHeures() }} h</td>
                        <td class="text-right">{{ number_format($table->prix_par_heure, 0, ',', ' ') }} FCFA/h</td>
                        <td class="text-right">
                            <strong>{{ number_format($commande->getFraisSalle(), 0, ',', ' ') }} FCFA</strong>
                        </td>
                    </tr>
                    @endif
                </tbody>
            </table>
        </div>

        <!-- Totaux -->
        <div class="totals">
            <div class="total-row">
                <div class="total-label">Sous-total:</div>
                <div class="total-value">{{ number_format($facture->montant_total, 0, ',', ' ') }} FCFA</div>
            </div>
            @if($facture->montant_taxe > 0)
            <div class="total-row">
                <div class="total-label">TVA (18%):</div>
                <div class="total-value">{{ number_format($facture->montant_taxe, 0, ',', ' ') }} FCFA</div>
            </div>
            @endif
            <div class="total-final">
                <div class="total-row" style="padding: 0;">
                    <div class="total-label">TOTAL:</div>
                    <div class="total-value">{{ number_format($facture->montant_total, 0, ',', ' ') }} FCFA</div>
                </div>
            </div>
        </div>

        <!-- Informations de paiement -->
        <div class="paiement-section">
            <div class="paiement-info">
                <div style="margin-bottom: 10px;">
                    <strong>Moyen de paiement:</strong>
                    @if($paiement->moyen_paiement->value === 'especes')
                        <span class="badge badge-especes">💵 ESPÈCES</span>
                    @elseif($paiement->moyen_paiement->value === 'wave')
                        <span class="badge badge-wave">📱 WAVE</span>
                    @elseif($paiement->moyen_paiement->value === 'orange_money')
                        <span class="badge badge-orange">📱 ORANGE MONEY</span>
                    @else
                        <span class="badge badge-carte">💳 CARTE BANCAIRE</span>
                    @endif
                </div>
                
                @if($paiement->moyen_paiement->value === 'especes')
                <div style="font-size: 13px;">
                    <div><strong>Montant reçu:</strong> {{ number_format($paiement->montant_recu, 0, ',', ' ') }} FCFA</div>
                    <div><strong>Monnaie rendue:</strong> {{ number_format($paiement->monnaie_rendue, 0, ',', ' ') }} FCFA</div>
                </div>
                @endif

                @if($paiement->transaction_id)
                <div style="font-size: 11px; margin-top: 5px;">
                    <strong>Transaction ID:</strong> {{ $paiement->transaction_id }}
                </div>
                @endif
                
                <div style="margin-top: 10px; font-size: 12px;">
                    <strong>✅ Paiement validé le:</strong> {{ $paiement->updated_at->format('d/m/Y à H:i') }}
                </div>
            </div>
        </div>

        <!-- Pied de page -->
        <div class="footer">
            <div class="thank-you">Merci de votre visite ! 🙏</div>
            <div>À très bientôt au {{ $restaurant['nom'] }} !</div>
            <div style="margin-top: 10px; font-size: 10px;">
                Document généré automatiquement - {{ now()->format('d/m/Y à H:i') }}
            </div>
        </div>
    </div>
</body>
</html>

