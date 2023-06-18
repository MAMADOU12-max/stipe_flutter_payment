import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_html/flutter_html.dart';
// import 'package:flutter_stripe_payment/flutter_stripe_payment.dart';


// _paymentItems(String price) => [
//       PaymentItem(
//         label:
//             '<Add Your merchant name or the displayName you added in the json file apple_pay.json ex:Facebook',
//         amount: '$price',
//         status: PaymentItemStatus.final_price,
//       )
//     ];

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

   Map<String, dynamic>? paymentIntent; 
   final _formKey = GlobalKey<FormState>();

  String? account_Number;
  String? routingNumber;
  String? countryCode;
  String? currency;
  String? accountHolderName;
  String? accountHolderType;

  // void initiatePayment() {
  //   if (_formKey.currentState!.validate()) {
  //     // All form fields are valid, proceed with payment
  //     BankAccount bankAccount = BankAccount(
  //       id: 'BANK_ACCOUNT_ID', // Replace with your own bank account ID
  //       accountNumber: account_Number,
  //       routingNumber: routingNumber,
  //       country: countryCode,
  //       currency: currency,
  //       accountHolderName: accountHolderName,
  //       accountHolderType: accountHolderType,
  //     );

  //     // Create a bank token and send it to the server
  //     Token token = await StripePayment.createTokenWithBankAccount(bankAccount);
  //     sendTokenToServer(token);
  //   }
  // }

  // void sendTokenToServer(Token token) {
  //   // Send the token to your server-side code for further processing
  //   // Implement your server-side logic to handle the token securely
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apple Pay Example'),
      ),
      // backgroundColor: Colors.blueGrey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Make Payment'),
              onPressed: () async {
                await makePayment();
              },
            ),
            //  Html(
            //   data:
            //       '<div><strong>Hello, world!</strong> This is some <br><br> HTML code.</div>',
            //   defaultTextStyle: TextStyle(fontSize: 18.0, color: Colors.amber),
            // ),
            //  Form(
            //   key: _formKey,
            //   child: Column(
            //     children: [
            //       TextFormField(
            //         onChanged: (value) => accountNumber = value,
            //         decoration: InputDecoration(labelText: 'Account Number'),
            //         validator: (value) {
            //           if (value.isEmpty) {
            //             return 'Please enter the account number';
            //           }
            //           return null;
            //         },
            //       ),
            //       TextFormField(
            //         onChanged: (value) => routingNumber = value,
            //         decoration: InputDecoration(labelText: 'Routing Number'),
            //         validator: (value) {
            //           if (value.isEmpty) {
            //             return 'Please enter the routing number';
            //           }
            //           return null;
            //         },
            //       ),
            //       TextFormField(
            //         onChanged: (value) => countryCode = value,
            //         decoration: InputDecoration(labelText: 'Country Code'),
            //         validator: (value) {
            //           if (value.isEmpty) {
            //             return 'Please enter the country code';
            //           }
            //           return null;
            //         },
            //       ),
            //       TextFormField(
            //         onChanged: (value) => currency = value,
            //         decoration: InputDecoration(labelText: 'Currency'),
            //         validator: (value) {
            //           if (value.isEmpty) {
            //             return 'Please enter the currency';
            //           }
            //           return null;
            //         },
            //       ),
            //       TextFormField(
            //         onChanged: (value) => accountHolderName = value,
            //         decoration: InputDecoration(labelText: 'Account Holder Name'),
            //         validator: (value) {
            //           if (value.isEmpty) {
            //             return 'Please enter the account holder name';
            //           }
            //           return null;
            //         },
            //       ),
            //       TextFormField(
            //         onChanged: (value) => accountHolderType = value,
            //         decoration: InputDecoration(labelText: 'Account Holder Type'),
            //         validator: (value) {
            //           if (value.isEmpty) {
            //             return 'Please enter the account holder type';
            //           }
            //           return null;
            //         },
            //       ),
            //       RaisedButton(
            //         onPressed: initiatePayment,
            //         child: Text('Make Payment'),
            //       ),
            //     ],
            //   ),
            // )
          
          ]
        )
      )
    );
  }

  Future<void> makePayment() async {
    try {
      paymentIntent = await createPaymentIntent('100', 'USD');

      //STEP 2: Initialize Payment Sheet
      await Stripe.instance
          .initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                  paymentIntentClientSecret: paymentIntent![
                      'client_secret'], //Gotten from payment intent
                  style: ThemeMode.light,
                  merchantDisplayName: 'Ikay'))
          .then((value) {});

      //STEP 3: Display Payment sheet
      displayPaymentSheet();
    } catch (err) {
      throw Exception(err);
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 100.0,
                      ),
                      SizedBox(height: 10.0),
                      Text("Payment Successful!"),
                    ],
                  ),
                ));

        paymentIntent = null;
      }).onError((error, stackTrace) {
        throw Exception(error);
      });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text("Payment Failed"),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('$e');
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
      };

      //Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['STRIPE_SECRET']}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  calculateAmount(String amount) {
    final calculatedAmout = (int.parse(amount)) * 100;
    return calculatedAmout.toString();
  }

}
// class MyHomeage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Apple Pay Example'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text('cool'),
//             ApplePayButton(
//               paymentConfigurationAsset: 'applepay.json',
//               paymentItems: _paymentItems,
//               style: ApplePayButtonStyle.black,
//               type: ApplePayButtonType.buy,
//               width: 200,
//               height: 50,
//               margin: const EdgeInsets.only(top: 15.0),
//               onPaymentResult: (value) {
//                 print(value);
//               },
//               onError: (error) {
//                 print(error);
//               },
//               loadingIndicator: const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
