import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products.dart';
import '../providers/product.dart';

/*
 *  Form inputs are only good for a widget in local state => use Stateful widget
 *  (what the users entered is important for this widget because we wanna validate it, and store there.
 *   Once user submits like pressing submit button, we typically wanna save that info into the App-wide state)
 *   EX: create a product, signup a users, whatever we're doing but until the submit button is pressed 
 *      we only wanna only manage that data in our local widget as users might cancel adding, might close the app...
 *      => So, the general app is not affected by the user input until it's really submitted
 *      => We want to manage the User input and validate it and so on, locally in this widget
 */
class EditProductScreen extends StatefulWidget {
  static const routeName = '/edit-product';

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

/* The state which is related to EditProductScreen widget */
class _EditProductScreenState extends State<EditProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageUrlController = TextEditingController();
  final _imageUrlFocusNode =
      FocusNode(); // Focus Node class for the image to be updated automatically
  final _form = GlobalKey<FormState>();
  var _editedProduct = Product(
    id: null,
    title: '',
    description: '',
    price: 0,
    imageUrl: '',
  );
  var _initValues = {
    'title': '',
    'description': '',
    'price': '',
    'imageUrl': '',
  };
  var _isInit = true;
  var _isLoading = false;

  @override
  void initState() {
    _imageUrlFocusNode.addListener(
        _updateImageUrl); // Tell it to run _updateImageUrl() whenever the focus changes.
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final productId = ModalRoute.of(context)!.settings.arguments as String?;
      if (productId != null) {
        _editedProduct =
            Provider.of<Products>(context, listen: false).findById(productId);
        _initValues = {
          'title': _editedProduct.title,
          'description': _editedProduct.description,
          'price': _editedProduct.price.toString(),
          // 'imageUrl': _editedProduct.imageUrl,
          'imageUrl': '',
        };
        _imageUrlController.text = _editedProduct.imageUrl;
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  // We have to dispose FocusNodes when the state gets cleared/when this object gets removed/when you'll leave that screen
  // because the FocusNodes otherwise will stick around in memory and lead to memory leak.
  void dispose() {
    // We should add dispose() to the State object where we're using FocusNodes
    _imageUrlFocusNode.removeListener(_updateImageUrl);
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageUrlController.dispose();
    _imageUrlFocusNode.dispose();
    super.dispose();
  }

  void _updateImageUrl() {
    // Check if we're not having focus anymore
    if (!_imageUrlFocusNode.hasFocus) {
      if ((!_imageUrlController.text.startsWith('http') &&
              !_imageUrlController.text.startsWith('https')) ||
          (!_imageUrlController.text.endsWith('.png') &&
              !_imageUrlController.text.endsWith('.jpg') &&
              !_imageUrlController.text.endsWith('.jpeg'))) {
        return;
      }
      // A bit hack cause we know that the "State" has updated, that we have an updated value in _imageUrlController
      // and we want to rebuild the screen to reflect that updated value in _imageUrlController since that value
      // in _imageUrlController is the image we want to preview.
      setState(() {});
    }
  }

  // How can we trigger validation if we don't use auto validate on the Form?
  // We can trigger it through the form key, when we save the form, then we can also call _form.currentState validate,
  // and this will trigger all the validators and this will return true if there's no errors. So if they all return null
  // and will return false if at least one validator returns a string and hence has an error.
  void _saveForm() async {
    final isValid = _form.currentState!
        .validate(); // Trigger all validators, then return true/false
    if (!isValid) {
      return; // Cancel the function execution
    }
    // Only save the form and output our results if the form is valid
    _form.currentState!.save();
    setState(() {
      _isLoading = true; // want to reflect this change on the UI
    });
    if (_editedProduct.id != null) {
      Provider.of<Products>(context, listen: false)
          .updateProduct(_editedProduct.id.toString(), _editedProduct);
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Sending a pop request
    } else {
      try {
        await Provider.of<Products>(context, listen: false)
            .addProduct(_editedProduct);
        // Catch error is reached if there's an error, but only the first catchError inline will execute then
      } catch (error) {
        // this error will be reached because we're throwing "error" inside "Products.dart" again.
        await showDialog<Null>(
          // returns a "Future" that resolves as soon as the user presses the "Okay" button
          // => so we wanna "await" for the result before going to the "finally" statement.
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('An error occurred'),
            content: const Text('Something went wrong!'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Okay'),
              ),
            ],
          ),
        );
      } finally {
        // This "finally" code always runs no matter if we succeed or fail.
        setState(() {
          _isLoading = false;
        });
        // Leave the page after finish (only pop once we're done with HTTP requests or once this was stored)
        // For the response to have arrived before we call pop.
        Navigator.of(context).pop(); // Sending a pop request
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Standalone page
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: <Widget>[
          IconButton(
            onPressed: _saveForm,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                // Use this Form: don't need add our own text editing controllers to get access to the values of our inputs
                key: _form,
                child: ListView(
                  // To avoid data loss in portrait mode: use Column with SingleChildScrollView
                  children: <Widget>[
                    TextFormField(
                      initialValue: _initValues['title'],
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        // FocusScope: a bit like "Theme", "Media query".
                        // Use "of(context)" to connect it to the page (to let it know where it is.)
                        // requestFocus(): will take FocusNode.
                        // When this "next button" is pressed in "the soft kb", we'll wanna focus the element with the "_priceFocusNode"
                        FocusScope.of(context).requestFocus(_priceFocusNode);
                      },
                      validator: (value) {
                        // Validating the "title" input
                        if (value!.isEmpty) {
                          return 'Please provide a value.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          title: value as String,
                          price: _editedProduct.price,
                          description: _editedProduct.description,
                          imageUrl: _editedProduct.imageUrl,
                          id: _editedProduct.id,
                          isFavorite: _editedProduct.isFavorite,
                        );
                      },
                    ),
                    TextFormField(
                      initialValue: _initValues['price'],
                      decoration: const InputDecoration(
                        labelText: 'Price',
                      ),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      focusNode: _priceFocusNode,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context)
                            .requestFocus(_descriptionFocusNode);
                      },
                      validator: (value) {
                        // Validation for "Price" input
                        if (value!.isEmpty) {
                          return 'Please enter a price.';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number.';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Please enter a number greater than zero.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          isFavorite: _editedProduct.isFavorite,
                          title: _editedProduct.title,
                          description: _editedProduct.description,
                          price: double.parse(value.toString()),
                          imageUrl: _editedProduct.imageUrl,
                        );
                      },
                    ),
                    TextFormField(
                      initialValue: _initValues['description'],
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      focusNode: _descriptionFocusNode,
                      validator: (value) {
                        // Validate 'description' input
                        if (value!.isEmpty) {
                          return 'Please enter a description.';
                        }
                        if (value.length < 10) {
                          return 'Should be at least 10 characters long.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          isFavorite: _editedProduct.isFavorite,
                          title: _editedProduct.title,
                          description: value.toString(),
                          price: _editedProduct.price,
                          imageUrl: _editedProduct.imageUrl,
                        );
                      },
                    ),
                    Row(
                      // For Image
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(
                            top: 8,
                            right: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: Colors.grey,
                            ),
                          ),
                          child: _imageUrlController.text.isEmpty
                              ? const Text('Enter a URL')
                              : FittedBox(
                                  child: Image.network(
                                    _imageUrlController.text,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        Expanded(
                          // Want to get access to the input before the form is submitted, because we wanna show
                          // a preview in the above Container
                          child: TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Image URL'),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            // _imageUrlController: is updated when we type into the "TextFormField"
                            controller:
                                _imageUrlController, // Don't have to do this if you just want to get the value when the form is submitted but before it's submitted.
                            focusNode: _imageUrlFocusNode,
                            onFieldSubmitted: (_) {
                              _saveForm();
                            },
                            // Validation for the input of Image URL
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter an image URL.';
                              }
                              if (!value.startsWith('http') &&
                                  !value.startsWith('https')) {
                                return 'Please enter a valid URL.';
                              }
                              if (!value.endsWith('.png') &&
                                  !value.endsWith('.jpg') &&
                                  !value.endsWith('.jpeg')) {
                                return 'Please enter a valid image URL.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _editedProduct = Product(
                                id: _editedProduct.id,
                                isFavorite: _editedProduct.isFavorite,
                                title: _editedProduct.title,
                                description: _editedProduct.description,
                                price: _editedProduct.price,
                                imageUrl: value.toString(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/*
    Flutter doesn't have a default listener for when this loses focus
    Setup our own listeners: 
      - With the help of FocusNode -> Let's add a new FocusNode for the imageUrlFocusNode -> have to dispose of that when the state object gets destroyed.
      - We can use that imageUrlFocusNode not to requestFocus for it once we're done with the description as mentioned before,
        that's not really possible but we can nonetheless add this "FocusNode" to our "TextFormField" for the "imageUrl" because we can now set our own listener and when
        this loses focus, then we can react to this. Well, make sure we updated the UI and use the "_imageUrlController" to show a preview.
      - So for that, we need to set up our own listener to the imageUrlFocusNode. It's attached to that "TextFormField" down there, 
        and therefore, it keeps track of whether that's focused or not. So we just need to listen to changes in that focus. For that, initState
        is a good place to setup that initial listener and add it to that "FocusNode", then we point at a function which should be executed whenever the focus changes.
        That function is named "_updateImageUrl" 
        + Note: we don't want to execute it when addListener() gets parsed/read. I just want to use the pointer at this function to tell Flutter
                that I want to execute this "updateImageUrl()" whenever the focus changes. We also have to clear that listener when we dispose of that state
*/
