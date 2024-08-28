import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_product_screen.dart'; // Import the new screen
import 'edit_product_screen.dart'; // Import the edit screen
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  print("hola mundo");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Inventory',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 10, 185, 198)
          ),
        ),
        home: MyHomePage(),
      );
  
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<dynamic>> _future;
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData(); // Fetch initial data
    _future = _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    filterSearchResults(_searchController.text);
  }

  Future<List<dynamic>> _fetchProducts() async {
    final response = await Supabase.instance.client
        .from('producto')
        .select()
        .order('name', ascending: true);

    _allProducts = List<dynamic>.from(response);
    _filteredProducts = _allProducts; // Initially, show all products
    return _allProducts;
  }
  Future<void> _refreshData() async {
    setState(() {
      _future = _fetchProducts(); // Refresh the data
    });
  }

  void filterSearchResults(String query) {
    List<dynamic> results = [];
    print("query:"+ query);
    if (query.isNotEmpty) {
      results = _allProducts
          .where((product) => product['name']
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    } else {
      results = _allProducts;
    }
    setState(() {
      _filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            title: Text('Tienda'),
            elevation: 0.0,
            backgroundColor: Color.fromARGB(255, 183, 229, 248),
            // Add the hamburger icon to the AppBar
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  child: Text(
                    'Tienda',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 2, 13),
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () {
                    // Handle the onTap here
                    Navigator.pop(context); // Close the drawer
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Agregar Precios'),
                  onTap: () {
                    // Handle the onTap here
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(
                          onProductAdded: _refreshData,
                        )),
                    ); // Navigate to the form screen
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  onTap: () {
                    // Handle the onTap here
                    Navigator.pop(context); // Close the drawer
                  },
                ),
              ],
            ),
          ),
          
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0), // Adjust the padding
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: "Busca el producto",
                        hintText: "Buscar...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  // final product = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _filteredProducts[index];
                        return Column(
                          children: [
                            ListTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item['name']),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProductScreen(
                                            productId: item['id'].toString(),
                                            currentName: item['name'],
                                            currentPrice: (item['price'] as num).toDouble(),
                                            onProductUpdated: _refreshData,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'S/ ${item['price']}',
                                      style: TextStyle(color: Colors.blue), // Highlight clickable text
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(), // Add a divider below each ListTile
                          ],
                        );
                      },
                      childCount: _filteredProducts.length,
                    ),
                  );
                },
              ),
            ],
          ),
        );
  }
}
