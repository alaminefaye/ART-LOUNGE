<!DOCTYPE html>
<html lang="en" class="light-style layout-menu-fixed" dir="ltr" data-theme="theme-default" data-assets-path="{{ asset('assets/') }}" data-template="vertical-menu-template-free">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0" />
    <title>@yield('title', 'Dashboard') - {{ config('app.name') }}</title>
    <meta name="description" content="@yield('description', '')" />
    
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="{{ asset('assets/img/favicon/favicon.ico') }}" />
    
    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Public+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,300;1,400;1,500;1,600;1,700&display=swap" rel="stylesheet" />
    
    <!-- Icons -->
    <link rel="stylesheet" href="{{ asset('assets/vendor/fonts/boxicons.css') }}" />
    
    <!-- Core CSS -->
    <link rel="stylesheet" href="{{ asset('assets/vendor/css/core.css') }}" class="template-customizer-core-css" />
    <link rel="stylesheet" href="{{ asset('assets/vendor/css/theme-default.css') }}" class="template-customizer-theme-css" />
    <link rel="stylesheet" href="{{ asset('assets/css/demo.css') }}" />
    
    <!-- Vendors CSS -->
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/perfect-scrollbar/perfect-scrollbar.css') }}" />
    @stack('vendor-css')
    
    <!-- Page CSS -->
    @stack('page-css')
    
    <!-- Helpers -->
    <script src="{{ asset('assets/vendor/js/helpers.js') }}"></script>
    <script src="{{ asset('assets/js/config.js') }}"></script>
</head>

<body>
    <!-- Layout wrapper -->
    <div class="layout-wrapper layout-content-navbar">
        <div class="layout-container">
            <!-- Menu -->
            <aside id="layout-menu" class="layout-menu menu-vertical menu bg-menu-theme">
                <div class="app-brand demo">
                    <a href="{{ route('dashboard') }}" class="app-brand-link d-flex align-items-center">
                        <img src="{{ asset('assets/img/logo.png') }}" alt="Logo" style="height: 64px; width: auto;" />
                    </a>
                    <a href="javascript:void(0);" class="layout-menu-toggle menu-link text-large ms-auto d-block d-xl-none">
                        <i class="bx bx-chevron-left bx-sm align-middle"></i>
                    </a>
                </div>
                
                <div class="menu-inner-shadow"></div>
                
                <ul class="menu-inner py-1">
                    <!-- Dashboard -->
                    @can('view_dashboard')
                    <li class="menu-item {{ request()->routeIs('dashboard') ? 'active' : '' }}">
                        <a href="{{ route('dashboard') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-home-circle"></i>
                            <div>Dashboard</div>
                        </a>
                    </li>
                    @endcan
                    
                    @can('view_reports')
                    <li class="menu-item {{ request()->routeIs('rapport.*') ? 'active' : '' }}">
                        <a href="{{ route('rapport.index') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-bar-chart-alt-2"></i>
                            <div>Rapport</div>
                        </a>
                    </li>
                    @endcan
                    
                    <!-- Tables -->
                    @can('view_tables')
                    <li class="menu-item {{ request()->routeIs('tables.*') ? 'active' : '' }}">
                        <a href="{{ route('tables.index') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-grid-alt"></i>
                            <div>Tables</div>
                        </a>
                    </li>
                    @endcan
                    
                    <!-- Réservations -->
                    @can('view_reservations')
                    <li class="menu-item {{ request()->routeIs('reservations.*') ? 'active' : '' }}">
                        <a href="{{ route('reservations.index') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-calendar"></i>
                            <div>Réservations</div>
                        </a>
                    </li>
                    @endcan
                    
                    <!-- Menu -->
                    @can('view_menu')
                    <li class="menu-item {{ request()->routeIs('menu.*') ? 'active open' : '' }}">
                        <a href="javascript:void(0);" class="menu-link menu-toggle">
                            <i class="menu-icon tf-icons bx bx-food-menu"></i>
                            <div>Menu</div>
                        </a>
                        <ul class="menu-sub">
                            <li class="menu-item {{ request()->routeIs('menu.categories.*') ? 'active' : '' }}">
                                <a href="{{ route('menu.categories.index') }}" class="menu-link">
                                    <div>Catégories</div>
                                </a>
                            </li>
                            <li class="menu-item {{ request()->routeIs('menu.products.*') ? 'active' : '' }}">
                                <a href="{{ route('menu.products.index') }}" class="menu-link">
                                    <div>Produits</div>
                                </a>
                            </li>
                        </ul>
                    </li>
                    @endcan
                    
                    <!-- Commandes -->
                    @can('view_orders')
                    <li class="menu-item {{ request()->routeIs('commandes.*') ? 'active' : '' }}">
                        <a href="{{ route('commandes.index') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-receipt"></i>
                            <div>Commandes</div>
                        </a>
                    </li>
                    @endcan
                    
                    <!-- Caisse -->
                    @can('access_cashier')
                    <li class="menu-item {{ request()->routeIs('caisse.index') || request()->routeIs('caisse.payer') ? 'active' : '' }}">
                        <a href="{{ route('caisse.index') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-dollar-circle"></i>
                            <div>Caisse</div>
                        </a>
                    </li>
                    
                    <!-- Sessions de Caisse (Bilan du jour) -->
                    @can('manage_sessions')
                    <li class="menu-item {{ request()->routeIs('caisse.sessions.*') ? 'active' : '' }}">
                        <a href="{{ route('caisse.sessions.index') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-time-five"></i>
                            <div>Bilan du jour (Sessions)</div>
                        </a>
                    </li>
                    @endcan
                    
                    <!-- Paiements (Historique) -->
                    <li class="menu-item {{ request()->routeIs('caisse.historique') ? 'active' : '' }}">
                        <a href="{{ route('caisse.historique') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-credit-card"></i>
                            <div>Historique Paiements</div>
                        </a>
                    </li>
                    @endcan
 
                    <!-- Avis -->
                    @can('view_avis')
                    <li class="menu-item {{ request()->routeIs('avis.*') ? 'active' : '' }}">
                        <a href="{{ route('avis.index') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-star"></i>
                            <div>Avis</div>
                        </a>
                    </li>
                    @endcan
                    
                    @can('view_roles')
                    <!-- Rôles & Permissions -->
                    <li class="menu-item {{ request()->routeIs('roles.*') ? 'active' : '' }}">
                        <a href="{{ route('roles.index') }}" class="menu-link">
                            <i class="menu-icon tf-icons bx bx-shield"></i>
                            <div>Rôles & Permissions</div>
                        </a>
                    </li>
                    @endcan
                    
                    @can('view_users')
                    <!-- Utilisateurs -->
                    <li class="menu-item {{ request()->routeIs('users.*') || request()->routeIs('serveurs.*') ? 'active open' : '' }}">
                        <a href="javascript:void(0);" class="menu-link menu-toggle">
                            <i class="menu-icon tf-icons bx bx-group"></i>
                            <div>Membres (Staff / Serveurs)</div>
                        </a>
                        <ul class="menu-sub">
                            <li class="menu-item {{ request()->routeIs('users.*') ? 'active' : '' }}">
                                <a href="{{ route('users.index') }}" class="menu-link">
                                    <div>Utilisateurs (Accès Système)</div>
                                </a>
                            </li>
                            <li class="menu-item {{ request()->routeIs('serveurs.*') ? 'active' : '' }}">
                                <a href="{{ route('serveurs.index') }}" class="menu-link">
                                    <div>Serveurs (POS)</div>
                                </a>
                            </li>
                        </ul>
                    </li>
                    @endcan
                    
                    @can('view_customers')
                    <!-- Clients & Fidélité -->
                    <li class="menu-item {{ request()->routeIs('clients.*') || request()->routeIs('fidelity.*') || request()->routeIs('payment-methods.*') ? 'active open' : '' }}">
                        <a href="javascript:void(0);" class="menu-link menu-toggle">
                            <i class="menu-icon tf-icons bx bx-group"></i>
                            <div>Clients & Fidélité</div>
                        </a>
                        <ul class="menu-sub">
                            <li class="menu-item {{ request()->routeIs('clients.index') || request()->routeIs('clients.show') || request()->routeIs('clients.edit') ? 'active' : '' }}">
                                <a href="{{ route('clients.index') }}" class="menu-link">
                                    <div>Clients</div>
                                </a>
                            </li>
                            @can('manage_loyalty')
                            <li class="menu-item {{ request()->routeIs('fidelity.*') ? 'active' : '' }}">
                                <a href="{{ route('fidelity.edit') }}" class="menu-link">
                                    <div>Paramètres points fidélité</div>
                                </a>
                            </li>
                            @endcan
                            @can('manage_payment_methods')
                            <li class="menu-item {{ request()->routeIs('payment-methods.*') ? 'active' : '' }}">
                                <a href="{{ route('payment-methods.edit') }}" class="menu-link">
                                    <div>Moyens de paiement (Wave / Orange Money)</div>
                                </a>
                            </li>
                            @endcan
                        </ul>
                    </li>
                    @endcan
                </ul>
            </aside>
            <!-- / Menu -->
            
            <!-- Layout container -->
            <div class="layout-page">
                <!-- Navbar -->
                <nav class="layout-navbar container-xxl navbar navbar-expand-xl navbar-detached align-items-center bg-navbar-theme" id="layout-navbar">
                    <div class="layout-menu-toggle navbar-nav align-items-xl-center me-3 me-xl-0 d-xl-none">
                        <a class="nav-item nav-link px-0 me-xl-4" href="javascript:void(0)">
                            <i class="bx bx-menu bx-sm"></i>
                        </a>
                    </div>
                    
                    <div class="navbar-nav-right d-flex align-items-center" id="navbar-collapse">
                        <!-- Search -->
                        <div class="navbar-nav align-items-center">
                            <div class="nav-item d-flex align-items-center">
                                <i class="bx bx-search fs-4 lh-0"></i>
                                <input type="text" class="form-control border-0 shadow-none" placeholder="Search..." aria-label="Search..." />
                            </div>
                        </div>
                        <!-- /Search -->
                        
                        <ul class="navbar-nav flex-row align-items-center ms-auto">
                            <!-- User -->
                            <li class="nav-item navbar-dropdown dropdown-user dropdown">
                                <a class="nav-link dropdown-toggle hide-arrow" href="javascript:void(0);" data-bs-toggle="dropdown">
                                    <div class="avatar avatar-online">
                                        <img src="{{ asset('assets/img/avatars/1.png') }}" alt class="w-px-40 h-auto rounded-circle" />
                                    </div>
                                </a>
                                <ul class="dropdown-menu dropdown-menu-end">
                                    <li>
                                        <a class="dropdown-item" href="#">
                                            <div class="d-flex">
                                                <div class="flex-shrink-0 me-3">
                                                    <div class="avatar avatar-online">
                                                        <img src="{{ asset('assets/img/avatars/1.png') }}" alt class="w-px-40 h-auto rounded-circle" />
                                                    </div>
                                                </div>
                                                <div class="flex-grow-1">
                                                    <span class="fw-semibold d-block">{{ Auth::check() ? Auth::user()->name : 'User' }}</span>
                                                    <small class="text-muted">Admin</small>
                                                </div>
                                            </div>
                                        </a>
                                    </li>
                                    <li>
                                        <div class="dropdown-divider"></div>
                                    </li>
                                    <li>
                                        <a class="dropdown-item" href="#">
                                            <i class="bx bx-user me-2"></i>
                                            <span class="align-middle">My Profile</span>
                                        </a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item" href="#">
                                            <i class="bx bx-cog me-2"></i>
                                            <span class="align-middle">Settings</span>
                                        </a>
                                    </li>
                                    <li>
                                        <div class="dropdown-divider"></div>
                                    </li>
                                    <li>
                                        <form method="POST" action="{{ route('logout') }}">
                                            @csrf
                                            <button type="submit" class="dropdown-item">
                                                <i class="bx bx-power-off me-2"></i>
                                                <span class="align-middle">Log Out</span>
                                            </button>
                                        </form>
                                    </li>
                                </ul>
                            </li>
                            <!--/ User -->
                        </ul>
                    </div>
                </nav>
                <!-- / Navbar -->
                
                <!-- Content wrapper -->
                <div class="content-wrapper">
                    <!-- Content -->
                    <div class="container-xxl flex-grow-1 container-p-y">
                        @if(session('success'))
                            <div class="alert alert-success alert-dismissible" role="alert">
                                {{ session('success') }}
                                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                            </div>
                        @endif
                        
                        @if(session('error'))
                            <div class="alert alert-danger alert-dismissible" role="alert">
                                {{ session('error') }}
                                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                            </div>
                        @endif
                        
                        @yield('content')
                    </div>
                    <!-- / Content -->
                    
                    <!-- Footer -->
                    <footer class="content-footer footer bg-footer-theme">
                        <div class="container-xxl d-flex flex-wrap justify-content-between py-2 flex-md-row flex-column">
                            <div class="mb-2 mb-md-0">
                                © <script>document.write(new Date().getFullYear());</script>, made with ❤️ by
                                <a href="https://themeselection.com" target="_blank" class="footer-link fw-bolder">ThemeSelection</a>
                            </div>
                            <div>
                                <a href="https://themeselection.com/license/" class="footer-link me-4" target="_blank">License</a>
                                <a href="https://themeselection.com/" target="_blank" class="footer-link me-4">More Themes</a>
                                <a href="https://themeselection.com/demo/sneat-bootstrap-html-admin-template/documentation/" target="_blank" class="footer-link me-4">Documentation</a>
                                <a href="https://github.com/themeselection/sneat-html-admin-template-free/issues" target="_blank" class="footer-link me-4">Support</a>
                            </div>
                        </div>
                    </footer>
                    <!-- / Footer -->
                    
                    <div class="content-backdrop fade"></div>
                </div>
                <!-- Content wrapper -->
            </div>
            <!-- / Layout page -->
        </div>
        
        <!-- Overlay -->
        <div class="layout-overlay layout-menu-toggle"></div>
    </div>
    <!-- / Layout wrapper -->
    
    <!-- Core JS -->
    <script src="{{ asset('assets/vendor/libs/jquery/jquery.js') }}"></script>
    <script src="{{ asset('assets/vendor/libs/popper/popper.js') }}"></script>
    <script src="{{ asset('assets/vendor/js/bootstrap.js') }}"></script>
    <script src="{{ asset('assets/vendor/libs/perfect-scrollbar/perfect-scrollbar.js') }}"></script>
    <script src="{{ asset('assets/vendor/js/menu.js') }}"></script>
    
    <!-- Vendors JS -->
    @stack('vendor-js')
    
    <!-- Main JS -->
    <script src="{{ asset('assets/js/main.js') }}"></script>
    
    <!-- Page JS -->
    @stack('page-js')
</body>
</html>
