import 'dart:convert';
import 'package:dao/walletConnectCred.dart';
import 'package:ethers/ethers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_connect/wallet_connect.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'eth_conversions.dart';

class Web3Connect {
  Web3Connect(this.context);
  String account = "";
  late WalletConnectEthereumCredentials credentials;
  late WalletConnect connector;
  late WCClient _wcClient;
  late SharedPreferences _prefs;
  WCSessionStore? _sessionStore;
  String rpcUrl =
      'https://rinkeby.infura.io/v3/337d4f8bfef54a519652b6b43b613a72';
  late SessionStatus? session;
  int chainId = 4; //default rinkeby
  String contract = "";
  String balance = "";
  final BuildContext context;
  Web3Client client = Web3Client("", Client());

  enterRpcUrl(String rpcUrl) {
    this.rpcUrl = rpcUrl;
  }

  enterChainId(int chainId) {
    this.chainId = chainId;
  }

  connect() async {
    await _walletConnect();
  }

  disconnect() async {
    await connector.killSession();
  }

  transation(Transaction transaction) async {
    try {
      Transaction transaction = Transaction(
        from: EthereumAddress.fromHex(account),
        to: EthereumAddress.fromHex(
            "0xc160Efc3af51ebc6fC4c517cA941a6999Ce0beC0"),
        value: EtherAmount.inWei(BigInt.from(1000000000000000000 * 0.1)),
      );
      EthereumWalletConnectProvider provider =
          EthereumWalletConnectProvider(connector);
      final credentials = WalletConnectEthereumCredentials(provider: provider);

      var snackBar = const SnackBar(
          content: Text('Please confirm transaction in metamask'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      final txBytes = await client.sendTransaction(credentials, transaction);
    } catch (err) {
      print(err);
      if (err == -32000) {
        var snackBar = const SnackBar(
            content: Text('Please confirm transaction in metamask'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  getBalance() async {
    var provider = ethers.providers.jsonRpcProvider(url: rpcUrl);
    final balancec = await provider.getBalance(account);
    return ethers.utils.formatEther(balancec);
  }

  _walletConnect() async {
    connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'WalletConnect',
        description: 'WalletConnect Developer App',
        url: 'https://walletconnect.org',
        icons: [
          'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
        ],
      ),
    );
    // Subscribe to events
    connector.on('connect', (session) => print(session));
    connector.on('session_update', (payload) => print(payload));
    connector.on('disconnect', (session) => print(session));
    connector.on('transaction', (payload) => print(payload));
    //Create a new session
    //await launch uri lets you choose which wallet you want to connect to
    if (!connector.connected) {
      session = await connector.createSession(
          chainId: chainId, onDisplayUri: (uri) async => {await launch(uri)});
    }
    account = session!.accounts[0];

    if (account != "") {
      client = Web3Client(rpcUrl, Client());
      EthereumWalletConnectProvider provider =
          EthereumWalletConnectProvider(connector);
      credentials = WalletConnectEthereumCredentials(provider: provider);
      // contract = YourContract(address: "contractAddr", client: client);
    }
  }
}
