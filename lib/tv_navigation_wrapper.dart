import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wrapper que maneja la navegación específica para Android TV
/// Soluciona los problemas de focus y navegación con control remoto
class TVNavigationWrapper extends StatefulWidget {
  final Widget child;
  final bool isMainScreen;
  
  const TVNavigationWrapper({
    Key? key,
    required this.child,
    this.isMainScreen = false,
  }) : super(key: key);

  @override
  State<TVNavigationWrapper> createState() => _TVNavigationWrapperState();
}

class _TVNavigationWrapperState extends State<TVNavigationWrapper> {
  late FocusNode _focusNode;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    // Auto-focus para la pantalla principal
    if (widget.isMainScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Mapeo de teclas del control remoto de Android TV
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        
        // Navegación direccional
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(TraversalDirection.up),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(TraversalDirection.down),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(TraversalDirection.left),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(TraversalDirection.right),
        
        // Botones especiales del control remoto
        LogicalKeySet(LogicalKeyboardKey.goBack): const _BackIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _BackIntent(),
        LogicalKeySet(LogicalKeyboardKey.browserBack): const _BackIntent(),
        
        // Botones de menú
        LogicalKeySet(LogicalKeyboardKey.contextMenu): const _MenuIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonY): const _MenuIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
              if (focusedWidget != null) {
                // Simular tap en el widget enfocado
                _simulateTap(FocusManager.instance.primaryFocus!.context!);
              }
              return null;
            },
          ),
          DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
            onInvoke: (DirectionalFocusIntent intent) {
              FocusManager.instance.primaryFocus?.nextFocus();
              return null;
            },
          ),
          _BackIntent: CallbackAction<_BackIntent>(
            onInvoke: (_BackIntent intent) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              return null;
            },
          ),
          _MenuIntent: CallbackAction<_MenuIntent>(
            onInvoke: (_MenuIntent intent) {
              // Abrir drawer si existe
              Scaffold.maybeOf(context)?.openDrawer();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: widget.isMainScreen,
          child: widget.child,
        ),
      ),
    );
  }
  
  void _simulateTap(BuildContext context) {
    // Encontrar el widget interactivo más cercano y activarlo
    final renderObject = context.findRenderObject();
    if (renderObject != null) {
      final center = renderObject.paintBounds.center;
      final globalPosition = renderObject.localToGlobal(center);
      
      // Simular tap down y up
      GestureBinding.instance.handlePointerEvent(
        PointerDownEvent(
          position: globalPosition,
          pointer: 1,
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 50), () {
        GestureBinding.instance.handlePointerEvent(
          PointerUpEvent(
            position: globalPosition,
            pointer: 1,
          ),
        );
      });
    }
  }
}

// Intent customizado para el botón de retroceso
class _BackIntent extends Intent {
  const _BackIntent();
}

// Intent customizado para el botón de menú
class _MenuIntent extends Intent {
  const _MenuIntent();
}

/// Widget focusable optimizado para Android TV
class TVFocusableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onFocus;
  final VoidCallback? onFocusLost;
  final bool autofocus;
  final String? semanticLabel;
  
  const TVFocusableWidget({
    Key? key,
    required this.child,
    this.onTap,
    this.onFocus,
    this.onFocusLost,
    this.autofocus = false,
    this.semanticLabel,
  }) : super(key: key);

  @override
  State<TVFocusableWidget> createState() => _TVFocusableWidgetState();
}

class _TVFocusableWidgetState extends State<TVFocusableWidget> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
      
      if (_hasFocus) {
        widget.onFocus?.call();
      } else {
        widget.onFocusLost?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: _hasFocus
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3.0,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(_hasFocus ? 4.0 : 7.0),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Drawer personalizado para Android TV con navegación por control remoto
class TVDrawer extends StatefulWidget {
  final List<TVDrawerItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;
  
  const TVDrawer({
    Key? key,
    required this.items,
    this.selectedIndex = 0,
    this.onItemSelected,
  }) : super(key: key);

  @override
  State<TVDrawer> createState() => _TVDrawerState();
}

class _TVDrawerState extends State<TVDrawer> {
  late int _focusedIndex;

  @override
  void initState() {
    super.initState();
    _focusedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Theme.of(context).drawerTheme.backgroundColor,
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.vpn_lock,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Hiddify Next TV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Items
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = index == widget.selectedIndex;
                
                return TVFocusableWidget(
                  autofocus: index == 0,
                  semanticLabel: item.title,
                  onTap: () {
                    widget.onItemSelected?.call(index);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          fontWeight: isSelected 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TVDrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  
  const TVDrawerItem({
    required this.title,
    required this.icon,
    this.onTap,
  });
}
