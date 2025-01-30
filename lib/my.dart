import 'package:flutter/material.dart';

class MyPage extends StatelessWidget {

  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child:
                Center(
                  child: Text("준비중 입니다!",
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 24
                          ),),
                )
        )
    );
  }
}
