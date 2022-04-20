import 'package:ethers/ethers.dart';
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'connection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Login(),
    );
  }
}

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    Web3Connect w3 = Web3Connect(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Login Page")),
      body: Center(
          child: ElevatedButton(
        child: const Text("Log In"),
        onPressed: () async {
          await w3.connect();
          if (w3.account != "") {
            Navigator.push(context,
                MaterialPageRoute(builder: ((context) => Home(w3: w3))));
          }
        },
      )),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key, required this.w3}) : super(key: key);
  final Web3Connect w3;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool killed = false;
  String balance = "0";
  String rpcUrl =
      'https://rinkeby.infura.io/v3/337d4f8bfef54a519652b6b43b613a72';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Text(balance),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () async {
                  var bal = await widget.w3.getBalance();
                  setState(() {
                    balance = bal;
                  });
                  // await widget.connection.credentials.sendTransaction(widget.connection);
                  // setState(() {
                  //   killed = true;
                  // });
                },
                child: const Text("Get balance")),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () async {
                  Transaction transaction = Transaction(
                    from: EthereumAddress.fromHex(widget.w3.account),
                    to: EthereumAddress.fromHex(
                        "0xc160Efc3af51ebc6fC4c517cA941a6999Ce0beC0"),
                    value: EtherAmount.inWei(BigInt.from(1000000000000000000 * 0.1)),
                  );
                  // String transactionHash = await widget.w3.transation(transaction);
                  // print(transactionHash);
                  widget.w3.transation(transaction);
                },
                child: const Text("Send Ether")),
            const SizedBox(
              height: 20,
            ),
            killed
                ? const Text(
                    "Session Killed",
                    style: TextStyle(color: Colors.red),
                  )
                : const Text("Session Connected"),
          ],
        ),
      ),
    );
  }
}
