<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Crypt;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable, HasApiTokens, HasRoles;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'fcm_token',
        'pin',
        'pin_encrypted',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'pin',
        'pin_encrypted',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Whether the user has a PIN configured
     */
    public function hasPin(): bool
    {
        return !empty($this->getAttributes()['pin']);
    }

    /**
     * PIN en clair pour affichage admin uniquement (chiffré avec APP_KEY).
     * Null si aucun PIN ou si le PIN a été défini avant l’ajout de pin_encrypted.
     */
    public function pinPlainForAdmin(): ?string
    {
        $cipher = $this->getAttributes()['pin_encrypted'] ?? null;
        if (empty($cipher)) {
            return null;
        }
        try {
            return Crypt::decryptString($cipher);
        } catch (\Throwable $e) {
            return null;
        }
    }

    /**
     * Notifications en base (liste, lu / non lu).
     */
    public function notifications()
    {
        return $this->hasMany(UserNotification::class)->orderByDesc('created_at');
    }

    public function avis()
    {
        return $this->hasMany(Avis::class)->orderByDesc('created_at');
    }

    /** Lien vers le profil Client (fidélité) si l'utilisateur est un client */
    public function client()
    {
        return $this->hasOne(Client::class);
    }

    public function caisseSessions()
    {
        return $this->hasMany(CaisseSession::class);
    }
}
