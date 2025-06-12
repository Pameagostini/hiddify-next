// tv_navigation_wrapper.dart
// Widget para manejar navegación D-pad en Android TV

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVNavigationWrapper extends StatefulWidget {
  final Widget child;
  final bool isSidebar;
  final VoidCallback? onNavigateToMain;
  final VoidCallback? onNavigateToSidebar;
  
  const TVNavigationWrapper({
    Key? key,
    required this.child,
    this.isSidebar = false,
    this.onNavigateToMain,
    this.onNavigateToSidebar,
  }) : super(key: key);

  @override
  _TVNavigationWrapperState createState() => _TVNavigationWrapperState();
}

class _TVNavigationWrapperState extends State<TVNavigationWrapper> {
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    // Auto-focus en sidebar cuando se inicia la app
    if (widget.isSidebar) {
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
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Navegación horizontal entre sidebar y contenido principal
          if (event.logicalKey == LogicalKeyboardKey.arrowRight && widget.isSidebar) {
            widget.onNavigateToMain?.call();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && !widget.isSidebar) {
            widget.onNavigateToSidebar?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}

// main_layout_tv.dart
// Layout principal modificado para Android TV

class MainLayoutTV extends StatefulWidget {
  @override
  _MainLayoutTVState createState() => _MainLayoutTVState();
}

class _MainLayoutTVState extends State<MainLayoutTV> {
  bool _sidebarFocused = true;
  int _selectedSidebarIndex = 0;
  final FocusNode _sidebarFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  
  final List<String> _sidebarItems = [
    'Home',
    'Proxies', 
    'Logs',
    'Settings',
    'About'
  ];
  
  final List<IconData> _sidebarIcons = [
    Icons.power_settings_new,
    Icons.wifi,
    Icons.list,
    Icons.settings,
    Icons.info,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sidebarFocusNode.requestFocus();
    });
  }

  void _navigateToMain() {
    setState(() {
      _sidebarFocused = false;
    });
    _mainFocusNode.requestFocus();
  }

  void _navigateToSidebar() {
    setState(() {
      _sidebarFocused = true;
    });
    _sidebarFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: Colors.red,
            child: TVNavigationWrapper(
              isSidebar: true,
              onNavigateToMain: _navigateToMain,
              child: Focus(
                focusNode: _sidebarFocusNode,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      setState(() {
                        _selectedSidebarIndex = 
                            (_selectedSidebarIndex - 1) % _sidebarItems.length;
                      });
                      return KeyEventResult.handled;
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      setState(() {
                        _selectedSidebarIndex = 
                            (_selectedSidebarIndex + 1) % _sidebarItems.length;
                      });
                      return KeyEventResult.handled;
                    } else if (event.logicalKey == LogicalKeyboardKey.select ||
                               event.logicalKey == LogicalKeyboardKey.enter) {
                      _handleSidebarSelection(_selectedSidebarIndex);
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: Column(
                  children: [
                    // Header del sidebar
                    Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Text(
                        'Hiddify Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Items del sidebar
                    Expanded(
                      child: ListView.builder(
                        itemCount: _sidebarItems.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedSidebarIndex == index && _sidebarFocused;
                          return Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.1) : null,
                              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                            child: ListTile(
                              leading: Icon(
                                _sidebarIcons[index],
                                color: Colors.white,
                              ),
                              title: Text(
                                _sidebarItems[index],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Contenido principal
          Expanded(
            child: TVNavigationWrapper(
              isSidebar: false,
              onNavigateToSidebar: _navigateToSidebar,
              child: Focus(
                focusNode: _mainFocusNode,
                child: Container(
                  color: Color(0xFF2D2D2D),
                  child: _buildMainContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedSidebarIndex) {
      case 0: // Home
        return _buildHomeContent();
      case 1: // Proxies
        return _buildProxiesContent();
      case 2: // Logs
        return _buildLogsContent();
      case 3: // Settings
        return _buildSettingsContent();
      case 4: // About
        return _buildAboutContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profile info
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'main Jack',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 10),
                Container(
                  width: 300,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.4, // 40% usado
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('161.71GB / 400GB', style: TextStyle(color: Colors.grey)),
                    Text('267 days remaining', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          // Connect button
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart,
              size: 60,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Tap to connect',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProxiesContent() {
    return Center(
      child: Text(
        'Proxies Content',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildLogsContent() {
    return Center(
      child: Text(
        'Logs Content',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return Center(
      child: Text(
        'Settings Content',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildAboutContent() {
    return Center(
      child: Text(
        'About Content',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  void _handleSidebarSelection(int index) {
    setState(() {
      _selectedSidebarIndex = index;
    });
    // Aquí puedes agregar lógica específica para cada selección
  }

  @override
  void dispose() {
    _sidebarFocusNode.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }
}
