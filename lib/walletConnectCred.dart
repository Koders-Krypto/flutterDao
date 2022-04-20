import 'dart:typed_data';
import 'package:dao/testerTransaction.dart';
import 'package:http/http.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
// ignore: implementation_imports
import 'package:web3dart/src/crypto/secp256k1.dart';
import 'package:web3dart/web3dart.dart';

class WalletConnectEthereumCredentials extends CustomTransactionSender {
  WalletConnectEthereumCredentials({required this.provider});

  final EthereumWalletConnectProvider provider;

  @override
  Future<EthereumAddress> extractAddress() {
    // TODO: implement extractAddress
    throw UnimplementedError();
  }

  @override
  Future<String> sendTransaction(Transaction transaction) async {
    final hash = await provider.sendTransaction(
      from: transaction.from!.hex,
      to: transaction.to?.hex,
      data: transaction.data,
      gas: transaction.maxGas,
      gasPrice: transaction.gasPrice?.getInWei,
      value: transaction.value?.getInWei,
      nonce: transaction.nonce,
    );
    return hash;
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) {
    // TODO: implement signToSignature
    throw UnimplementedError();
  }
}

class EthereumTransactionTester extends TransactionTester {
  final Web3Client ethereum;
  final EthereumWalletConnectProvider provider;

  EthereumTransactionTester._internal({
    required WalletConnect connector,
    required this.ethereum,
    required this.provider,
  }) : super(connector: connector);

  factory EthereumTransactionTester() {
    final ethereum = Web3Client('https://rinkeby.infura.io/v3/337d4f8bfef54a519652b6b43b613a72', Client());

    final connector = WalletConnect(
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

    final provider = EthereumWalletConnectProvider(connector);

    return EthereumTransactionTester._internal(
      connector: connector,
      ethereum: ethereum,
      provider: provider,
    );
  }

  @override
  Future<SessionStatus> connect({OnDisplayUriCallback? onDisplayUri}) async {
    return connector.connect(chainId: 4, onDisplayUri: onDisplayUri);
  }

  @override
  Future<void> disconnect() async {
    await connector.killSession();
  }

  @override
  Future<String> signTransaction(SessionStatus session) async {
    final sender = EthereumAddress.fromHex(session.accounts[0]);

     Transaction transaction = Transaction(
      from: sender,
      to: EthereumAddress.fromHex("0xc160Efc3af51ebc6fC4c517cA941a6999Ce0beC0"),
      value: EtherAmount.inWei(BigInt.from(1000000000000000000 * 0.1)),
    );

    final credentials = WalletConnectEthereumCredentials(provider: provider);

    // Sign the transaction
    final txBytes = await ethereum.sendTransaction(credentials, transaction);

    // Kill the session
    connector.killSession();

    return txBytes;
  }

  @override
  Future<String> signTransactions(SessionStatus session) {
    // TODO: implement signTransactions
    throw UnimplementedError();
  }
}
