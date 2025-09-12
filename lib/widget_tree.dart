import 'package:waterqualitymonitoring/auth.dart';
import 'package:waterqualitymonitoring/home_page.dart';
import 'package:waterqualitymonitoring/auth/login_page.dart';
import 'package:flutter/material.dart';

class WidgetTree extends StatefulWidget{
  const WidgetTree({super.key});
  
  @override
  State<WidgetTree> createState()=> _WidgetTreeState();
}

class _WidgetTreeState  extends State<WidgetTree>{
  @override
  Widget build(BuildContext context){
    return StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context,snapshot){
          if(snapshot.hasData){
            return HomePage();
          }else{
            return LoginPage();
          }
        },);
  }
}