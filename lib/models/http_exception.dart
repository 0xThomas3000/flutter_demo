// Because in the end, we want to throw that exception when we have some problems with our HTTP requests.
// My own HTTP exception class is now configured to always print the message here when we call ourException which would be
// a concrete instance of this class, or when we do print(ourException). In all these cases, it will trigger
// toString(), and now it will simply print that "message"
class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() {
    return message; // Print an error message
    // return super.toString(); // Instance of HttpException
  }
}
