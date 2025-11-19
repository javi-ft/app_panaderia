import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/perfil_cliente_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Panadería FLORI',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(), // Cambiado a SplashScreen
      routes: {
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

// SPLASH SCREEN AGREGADO
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Espera 2 segundos en el splash screen
    await Future.delayed(const Duration(seconds: 6));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(), // Va directo al Login
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // IMAGEN DEL LOGO
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  'assets/splash_logo.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.bakery_dining,
                      size: 80,
                      color: Colors.brown,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'FLORI',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    blurRadius: 15,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Panadería y Pastelería',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'El aroma que enamora… el sabor que conquista.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),

            const SizedBox(height: 20),

            Text(
              'Cargando...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TU LOGIN SCREEN ORIGINAL (TODO EL CÓDIGO QUE YA TENÍAS)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dniController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final String logoUrl =
      'https://lh3.googleusercontent.com/d/1omg43EfoMAS2riKZzJAg99ih_LFJIue7';

  // Validaciones
  bool get _isValidEmail {
    final email = _emailController.text.trim();
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool get _isValidPassword {
    final password = _passwordController.text;
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  bool get _passwordsMatch {
    return _passwordController.text == _confirmPasswordController.text;
  }

  bool get _isValidPhone {
    final phone = _phoneController.text.trim();
    return phone.length == 9 &&
        phone.startsWith('9') &&
        RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  bool get _isValidDNI {
    final dni = _dniController.text.trim();
    return dni.length == 8 && RegExp(r'^[0-9]+$').hasMatch(dni);
  }

  bool get _isValidName {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    return firstName.length >= 2 && lastName.length >= 2;
  }

  String? get _emailError {
    if (_emailController.text.isEmpty) return null;
    if (!_isValidEmail) return 'Ingresa un email válido';
    return null;
  }

  String? get _passwordError {
    if (_passwordController.text.isEmpty) return null;
    if (!_isValidPassword) {
      return 'Mín. 8 chars, mayúscula, minúscula, número y símbolo';
    }
    return null;
  }

  String? get _phoneError {
    if (_phoneController.text.isEmpty) return null;
    if (!_isValidPhone) {
      if (!_phoneController.text.startsWith('9')) {
        return 'El celular debe empezar con 9';
      }
      if (_phoneController.text.length != 9) {
        return 'El celular debe tener 9 dígitos';
      }
      return 'Ingresa un número de celular válido';
    }
    return null;
  }

  String? get _dniError {
    if (_dniController.text.isEmpty) return null;
    if (!_isValidDNI) {
      return 'El DNI debe tener 8 dígitos';
    }
    return null;
  }

  Future<void> _authenticate() async {
    // Ocultar teclado
    FocusScope.of(context).unfocus();

    // Validaciones básicas
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    if (!_isLogin) {
      // Validaciones para registro
      if (!_isValidName) {
        _showError('Los nombres y apellidos deben tener al menos 2 caracteres');
        return;
      }
      if (!_isValidDNI) {
        _showError('El DNI debe tener exactamente 8 dígitos');
        return;
      }
      if (!_isValidEmail) {
        _showError('Por favor ingresa un email válido');
        return;
      }
      if (!_isValidPhone) {
        _showError('El celular debe tener 9 dígitos y empezar con 9');
        return;
      }
      if (!_isValidPassword) {
        _showError('La contraseña no cumple con los requisitos de seguridad');
        return;
      }
      if (!_passwordsMatch) {
        _showError('Las contraseñas no coinciden');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Login
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _showSuccess('¡Bienvenido de vuelta!');
      } else {
        // Registro
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Actualizar perfil del usuario con nombre completo
        await userCredential.user!.updateDisplayName(
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}');

        _showSuccess('¡Cuenta creada exitosamente! ¡Bienvenido a FLORI!');
      }

      // Navegar al home después del éxito
      Future.delayed(const Duration(milliseconds: 1500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      });
    } on FirebaseAuthException catch (e) {
      String message = 'Error de autenticación';
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'email-already-in-use':
          message = 'El email ya está registrado';
          break;
        case 'weak-password':
          message = 'La contraseña es demasiado débil';
          break;
        case 'invalid-email':
          message = 'El formato del email es inválido';
          break;
        case 'network-request-failed':
          message = 'Error de conexión a internet';
          break;
        case 'operation-not-allowed':
          message = 'Operación no permitida';
          break;
        case 'too-many-requests':
          message = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      _showError(message);
    } catch (e) {
      _showError('Error inesperado: $e');
    }

    setState(() => _isLoading = false);
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _dniController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
  }

  // Formateadores para los campos
  void _formatPhone(String value) {
    if (value.length == 1 && value != '9') {
      _phoneController.text = '9';
      _phoneController.selection = const TextSelection.collapsed(offset: 1);
    }
  }

  void _formatDNI(String value) {
    if (value.length > 8) {
      _dniController.text = value.substring(0, 8);
      _dniController.selection = const TextSelection.collapsed(offset: 8);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _buildLogo(),
                const SizedBox(height: 24),

                // Título
                Text(
                  _isLogin ? 'Bienvenido a FLORI' : 'Crear Cuenta',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Inicia sesión en tu cuenta'
                      : 'Completa tus datos para registrarte',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Formulario
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Campos de registro (solo visible en registro)
                      if (!_isLogin) ..._buildRegisterFields(),

                      // Campo Email
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'tu@email.com',
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Colors.brown),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.brown, width: 2),
                          ),
                          errorText: _emailError,
                          errorMaxLines: 2,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Campo Contraseña
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: _isLogin
                              ? 'Ingresa tu contraseña'
                              : 'Crea una contraseña segura',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.brown),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.brown, width: 2),
                          ),
                          errorText: _passwordError,
                          errorMaxLines: 3,
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: _isLogin
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onSubmitted: (_) => _isLogin ? _authenticate() : null,
                        onChanged: (_) => setState(() {}),
                      ),

                      // Indicador de fortaleza de contraseña (solo en registro)
                      if (!_isLogin && _passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildPasswordStrength(),
                      ],

                      // Campo Confirmar Contraseña (solo en registro)
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Contraseña',
                            hintText: 'Repite tu contraseña',
                            prefixIcon: const Icon(Icons.lock_reset,
                                color: Colors.brown),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: _toggleConfirmPasswordVisibility,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.brown, width: 2),
                            ),
                            errorText:
                                _confirmPasswordController.text.isNotEmpty &&
                                        !_passwordsMatch
                                    ? 'Las contraseñas no coinciden'
                                    : null,
                          ),
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _authenticate(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botón de acción
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _authenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: Colors.brown.withOpacity(0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        _isLogin
                                            ? Icons.login
                                            : Icons.person_add,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isLogin
                                          ? 'Iniciar Sesión'
                                          : 'Crear Cuenta',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cambiar entre login y registro
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _clearForm();
                                });
                              },
                        child: Text(
                          _isLogin
                              ? '¿No tienes cuenta? Regístrate aquí'
                              : '¿Ya tienes cuenta? Inicia Sesión',
                          style: const TextStyle(
                            color: Colors.brown,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Información adicional
                const SizedBox(height: 32),
                Text(
                  'Panadería y Pastelería FLORI',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Desde 2020 sirviendo la mejor calidad',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Logo
  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(70),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(70),
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(70),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackLogo();
          },
        ),
      ),
    );
  }

  // Logo de respaldo
  Widget _buildFallbackLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.brown.shade600,
            Colors.orange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(70),
      ),
      child: const Icon(
        Icons.bakery_dining,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  // Campos adicionales para registro
  List<Widget> _buildRegisterFields() {
    return [
      // Campo DNI
      TextField(
        controller: _dniController,
        decoration: InputDecoration(
          labelText: 'DNI',
          hintText: '12345678',
          prefixIcon: const Icon(Icons.badge_outlined, color: Colors.brown),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.brown, width: 2),
          ),
          errorText: _dniError,
          counterText: '${_dniController.text.length}/8',
        ),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        maxLength: 8,
        onChanged: (value) {
          _formatDNI(value);
          setState(() {});
        },
      ),
      const SizedBox(height: 16),

      // Nombres y Apellidos en fila
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Nombres',
                hintText: 'Tus nombres',
                prefixIcon:
                    const Icon(Icons.person_outline, color: Colors.brown),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.brown, width: 2),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Apellidos',
                hintText: 'Tus apellidos',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.brown, width: 2),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Campo Celular
      TextField(
        controller: _phoneController,
        decoration: InputDecoration(
          labelText: 'Número de Celular',
          hintText: '912345678',
          prefixIcon: const Icon(Icons.phone_android, color: Colors.brown),
          prefixText: '+51 ',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.brown, width: 2),
          ),
          errorText: _phoneError,
          counterText: '${_phoneController.text.length}/9',
        ),
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        maxLength: 9,
        onChanged: (value) {
          _formatPhone(value);
          setState(() {});
        },
      ),
      const SizedBox(height: 8),
      // Información sobre el formato del celular
      Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            'Formato: 9XXXXXXX (9 dígitos, empieza con 9)',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];
  }

  // Indicador de fortaleza de contraseña
  Widget _buildPasswordStrength() {
    final strength = _calculatePasswordStrength(_passwordController.text);
    Color color;
    String text;
    String description;

    switch (strength) {
      case 1:
        color = Colors.red;
        text = 'Débil';
        description = 'Agrega más caracteres y tipos diferentes';
        break;
      case 2:
        color = Colors.orange;
        text = 'Regular';
        description = 'Puede mejorar, agrega símbolos';
        break;
      case 3:
        color = Colors.blue;
        text = 'Buena';
        description = 'Contraseña aceptable';
        break;
      case 4:
        color = Colors.green;
        text = 'Fuerte';
        description = '¡Excelente! Contraseña segura';
        break;
      default:
        color = Colors.grey;
        text = '';
        description = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Fortaleza: ',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Colors.grey.shade300,
          color: color,
          borderRadius: BorderRadius.circular(10),
          minHeight: 6,
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Requisitos: Mínimo 8 caracteres, incluyendo mayúscula, minúscula, número y símbolo (!@#\$%^&*)',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength;
  }
}
