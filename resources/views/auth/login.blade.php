@extends('layouts.auth')

@section('title', 'Connexion')

@section('content')
<!-- Connexion -->
<div class="card">
    <div class="card-body">
        <!-- Logo -->
        <div class="app-brand justify-content-center mb-4">
            <a href="{{ route('dashboard') }}" class="app-brand-link gap-2 d-flex flex-column align-items-center">
                <img src="{{ asset('assets/img/logo.png') }}" alt="Logo" class="app-brand-logo" style="height: 120px; width: auto;" />
                <span class="app-brand-text demo text-body fw-bolder mt-2">{{ config('app.name', 'ART MOMENTS') }}</span>
            </a>
        </div>
        <!-- /Logo -->
        <h4 class="mb-2">Bienvenue sur {{ config('app.name', 'ART MOMENTS') }} ! 👋</h4>
        <p class="mb-4">Connectez-vous à votre compte pour continuer</p>
        
        <form id="formAuthentication" class="mb-3" action="{{ route('login') }}" method="POST">
            @csrf
            <div class="mb-3">
                <label for="email" class="form-label">Email ou nom d'utilisateur</label>
                <input type="text" class="form-control @error('email') is-invalid @enderror" id="email" name="email" placeholder="Saisissez votre email ou nom d'utilisateur" autofocus value="{{ old('email') }}" />
                @error('email')
                    <div class="invalid-feedback">{{ $message }}</div>
                @enderror
            </div>
            <div class="mb-3 form-password-toggle">
                <div class="d-flex justify-content-between">
                    <label class="form-label" for="password">Mot de passe</label>
                </div>
                <div class="input-group input-group-merge">
                    <input type="password" id="password" class="form-control @error('password') is-invalid @enderror" name="password" placeholder="&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;" aria-describedby="password" />
                    <span class="input-group-text cursor-pointer"><i class="bx bx-hide"></i></span>
                    @error('password')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>
            </div>
            <div class="mb-3">
                <div class="form-check">
                    <input class="form-check-input" type="checkbox" id="remember-me" name="remember" />
                    <label class="form-check-label" for="remember-me"> Se souvenir de moi </label>
                </div>
            </div>
            <div class="mb-3">
                <button class="btn btn-primary d-grid w-100" type="submit">Se connecter</button>
            </div>
        </form>
        
    </div>
</div>
<!-- /Connexion -->
@endsection
