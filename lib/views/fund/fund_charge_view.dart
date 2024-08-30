import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gagyebbyu_fe/storage/TokenStorage.dart';
import 'package:http/http.dart' as http;

import '../../models/fund/fund_transaction_create.dart';
import '../../models/asset/asset_account.dart';

class FundChargeView extends StatefulWidget {
  final int fundId;

  FundChargeView({required this.fundId});

  @override
  _FundChargeViewState createState() => _FundChargeViewState();
}

class _FundChargeViewState extends State<FundChargeView> {
  final _formKey = GlobalKey<FormState>();
  final TokenStorage _tokenStorage = TokenStorage();
  int _amount = 0;
  String? _selectedAccount;
  String? _selectedBankName;
  List<AssetAccount> _accounts = [];
  bool _isLoading = true;

  final Color _primaryColor = Color(0xFFFF6B6B);
  final Color _backgroundColor = Color(0xFFF9FAFB);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF191F28);
  final Color _subTextColor = Color(0xFF8B95A1);

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    final url = Uri.parse('http://3.39.19.140:8080/api/asset-accounts');
    final accessToken = await _tokenStorage.getAccessToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _accounts = data.map((item) => AssetAccount.fromJson(item)).toList();
          if (_accounts.isNotEmpty) {
            // 초기 선택 계좌 설정
            _selectedAccount = _accounts[0].accountNumber;
            _selectedBankName = _accounts[0].bankName;
          }
          _isLoading = false;
        });
      } else {
        print('Failed to load accounts. Status code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching accounts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> createTransaction(FundTransactionCreate transaction) async {
    final url = Uri.parse('http://3.39.19.140:8080/api/fund/transaction/${widget.fundId}');
    final accessToken = await _tokenStorage.getAccessToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(transaction.toJson()),
      );

      if (response.statusCode == 201) {
        print('Transaction created successfully');
        _showCompletionDialog(); // 충전 완료 모달 다이얼로그 띄우기
      } else {
        print('Failed to create transaction. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error creating transaction: $e');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('충전 완료'),
          content: Text('충전이 완료되었습니다.'),
          actions: <Widget>[
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(true); // 이전 화면으로 돌아가기
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('충전하기', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)))
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountInput(),
                SizedBox(height: 24),
                _buildAccountSelection(),
                SizedBox(height: 32),
                _buildChargeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '충전할 금액',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
          ),
          SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              hintText: '금액 입력',
              hintStyle: TextStyle(color: _subTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _backgroundColor,
              suffixText: '원',
              suffixStyle: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
            ),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textColor),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '금액을 입력해주세요';
              }
              return null;
            },
            onSaved: (value) {
              _amount = int.parse(value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계좌 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _backgroundColor,
            ),
            value: _selectedAccount,
            items: _accounts.map((account) {
              return DropdownMenuItem<String>(
                value: account.accountNumber,
                child: Text('${account.bankName} ${account.accountNumber}',
                    style: TextStyle(color: _textColor)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAccount = value;
                _selectedBankName = _accounts
                    .firstWhere((account) => account.accountNumber == value)
                    .bankName;
              });
            },
          ),
          if (_selectedBankName != null) ...[
            SizedBox(height: 12),
            Text(
              '은행 이름: $_selectedBankName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _subTextColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChargeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            FundTransactionCreate newTransaction = FundTransactionCreate(
              amount: _amount,
              type: 'PLUS',
            );
            createTransaction(newTransaction);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('충전하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold ,color: _backgroundColor)),
      ),
    );
  }
}
