import 'package:ethers/ethers.dart';
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
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
          await w3.loadContract();
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
  String rpcUrl = 'https://rpc.ftm.tools/';

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
                  // var bal = await widget.w3.getBalance();
                  var mintStat = await widget.w3.mint() ?? "";
                  if (mintStat != "") {
                    var snackBar =
                        SnackBar(content: Text('Success:' + mintStat));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                  setState(() {
                    balance = "0";
                  });
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
                    value: EtherAmount.inWei(
                        BigInt.from(1000000000000000000 * 0.1)),
                  );
                  String transactionHash =
                      await widget.w3.transation(transaction) ?? "";
                  if (transactionHash != "") {
                    var snackBar =
                        SnackBar(content: Text('Success:' + transactionHash));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
                child: const Text("Send Fantom")),
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
