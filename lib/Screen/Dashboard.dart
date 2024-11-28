import 'dart:async';
import 'dart:convert';

import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Helper/Constant.dart';
import 'package:eshop_multivendor/Helper/PushNotificationService.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Helper/String.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Screen/Favorite.dart';
import 'package:eshop_multivendor/Screen/Login.dart';
import 'package:eshop_multivendor/Screen/MyProfile.dart';
import 'package:eshop_multivendor/Screen/Product_Detail.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'All_Category.dart';
import 'Cart.dart';
import 'HomePage.dart';
import 'NotificationLIst.dart';
import 'Sale.dart';
import 'Search.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Dashboard> with TickerProviderStateMixin {
  int _selBottom = 0;
  late TabController _tabController;
  bool _isNetworkAvail = true;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    super.initState();
    initDynamicLinks();
    _tabController = TabController(
      length: 5,
      vsync: this,
    );

    final pushNotificationService = PushNotificationService(
        context: context, tabController: _tabController);
    pushNotificationService.initialise();

    _tabController.addListener(
      () {
        Future.delayed(Duration(seconds: 0)).then(
          (value) {
            if (_tabController.index == 3) {
              if (CUR_USERID == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Login(),
                  ),
                );
                _tabController.animateTo(0);
              }
            }
          },
        );

        setState(
          () {
            _selBottom = _tabController.index;
          },
        );
      },
    );
  }

  void initDynamicLinks() async {
   /* FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;

      if (deepLink != null) {
        if (deepLink.queryParameters.length > 0) {
          int index = int.parse(deepLink.queryParameters['index']!);

          int secPos = int.parse(deepLink.queryParameters['secPos']!);

          String? id = deepLink.queryParameters['id'];

          String? list = deepLink.queryParameters['list'];

          getProduct(id!, index, secPos, list == "true" ? true : false);
        }
      }
    }, onError: (OnLinkErrorException e) async {
      print(e.message);
    });

    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      if (deepLink.queryParameters.length > 0) {
        int index = int.parse(deepLink.queryParameters['index']!);

        int secPos = int.parse(deepLink.queryParameters['secPos']!);

        String? id = deepLink.queryParameters['id'];

        // String list = deepLink.queryParameters['list'];

        getProduct(id!, index, secPos, true);
      }
    }*/
  }

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          ID: id,
        };

        // if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;
        Response response =
            await post(getProductApi, headers: headers, body: parameter)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          List<Product> items = [];

          items =
              (data as List).map((data) => new Product.fromJson(data)).toList();

          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ProductDetail(
                    index: list ? int.parse(id) : index,
                    model: list
                        ? items[0]
                        : sectionList[secPos].productList![index],
                    secPos: secPos,
                    list: list,
                  )));
        } else {
          if (msg != "Products Not Found !") setSnackbar(msg, context);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      {
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Confirm Exit"),
                content: Text("Are you sure you want to exit?"),
                actions: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: colors.primary
                    ),
                    child: Text("YES"),
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: colors.primary
                    ),
                    child: Text("NO"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            }
        );
        // if (_tabController.index != 0) {
        //   _tabController.animateTo(0);
        //   return false;
        // }
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.lightWhite,
          appBar: _getAppBar(),
          body: TabBarView(
            controller: _tabController,
            children: [
              HomePage(),
              AllCategory(),
              Sale(),
              Cart(
                fromBottom: true,
              ),
              MyProfile(),
            ],
          ),
          //fragments[_selBottom],
          bottomNavigationBar: _getBottomBar(),
        ),
      ),
    );
  }

  AppBar _getAppBar() {
    String? title;
    if (_selBottom == 1)
      title = getTranslated(context, 'CATEGORY');
    else if (_selBottom == 2)
      title = getTranslated(context, 'OFFER');
    else if (_selBottom == 3)
      title = getTranslated(context, 'MYBAG');
    else if (_selBottom == 4) title = getTranslated(context, 'PROFILE');

    return AppBar(
      
      elevation: 0,
      centerTitle: _selBottom == 0 ? true : false,
      leading: _selBottom == 0 ?
           Padding(
             padding: const EdgeInsets.only(left: 7),
             child: Image.asset(
                'assets/images/titleicon.png',
                //height: 40,
                //   width: 200,
                height: 34,
                // width: 45,
              ),
           ):null,


      title: _selBottom == 0
          ?  Container(
          decoration: BoxDecoration(
              border: Border.all(color: colors.primary),
              borderRadius: BorderRadius.circular(5)
          ),
          height: 40,
          // width: double.infinity,
          //padding: EdgeInsets.all(16),
          child:  TextField(
            readOnly: true,
            onTap: (){
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Search()));
            },
            decoration: InputDecoration(
              border:InputBorder.none ,
              //border: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
              contentPadding: EdgeInsets.only(top: 2),
              hintText: "Search",hintStyle: TextStyle(color: colors.primary.withOpacity(0.6),fontSize: 13),
              prefixIcon: Icon(Icons.search,color: colors.primary),
              suffixIcon: Icon(Icons.mic,color: colors.primary),

            ),
          )
        // TextField(
        //    readOnly: true,
        //     decoration: InputDecoration(
        //       hintText: 'Search',
        //       contentPadding: EdgeInsets.only(top: 10),
        //       border: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
        //       prefixIcon: Icon(Icons.search),
        //
        //     ),
        // ),
      )

      // Row(
      //   //mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     Expanded(
      //       flex: 2,
      //       child: Container(
      //      width: 50,
      //      height: 47,
      //      child: Image.asset('assets/images/titleicon.png'),
      //     ),
      //     ),
      //     Expanded(
      //       flex: 9,
      //       child: Container(
      //           decoration: BoxDecoration(
      //               border: Border.all(color: colors.primary),
      //               borderRadius: BorderRadius.circular(5)
      //           ),
      //           height: 40,
      //          // width: double.infinity,
      //           //padding: EdgeInsets.all(16),
      //           child:  TextField(
      //             readOnly: true,
      //             onTap: (){
      //               Navigator.push(
      //                   context, MaterialPageRoute(builder: (context) => Search()));
      //             },
      //             decoration: InputDecoration(
      //               border:InputBorder.none ,
      //               //border: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
      //               contentPadding: EdgeInsets.only(top: 2),
      //               hintText: "Search",hintStyle: TextStyle(color: colors.primary.withOpacity(0.6),fontSize: 13),
      //               prefixIcon: Icon(Icons.search,color: colors.primary),
      //               suffixIcon: Icon(Icons.mic,color: colors.primary),
      //
      //             ),
      //           )
      //         // TextField(
      //         //    readOnly: true,
      //         //     decoration: InputDecoration(
      //         //       hintText: 'Search',
      //         //       contentPadding: EdgeInsets.only(top: 10),
      //         //       border: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
      //         //       prefixIcon: Icon(Icons.search),
      //         //
      //         //     ),
      //         // ),
      //       ),
      //     )
      //   ],
      // )



      // InkWell(
      //         child: Center(
      //             child: SvgPicture.asset(
      //           imagePath + "search.svg",
      //           height: 20,
      //           color: colors.primary,
      //         )),
      //         onTap: () {
      //           Navigator.push(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (context) => Search(),
      //               ));
      //         },
      //       )
          :Text(title!,style: TextStyle(color: colors.primary,fontWeight: FontWeight.normal,fontSize: 18),),
      // iconTheme: new IconThemeData(color: colors.primary),
      // centerTitle:_curSelected == 0? false:true,
      actions: <Widget>[
        _selBottom == 0
            ? Container()
            : IconButton(
                icon: SvgPicture.asset(
                  imagePath + "search.svg",
                  height: 20,
                  color: colors.primary,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Search(),
                      ));
                }),

        _selBottom == 0
            ? Container()
            : IconButton(
          icon: SvgPicture.asset(
            imagePath + "desel_notification.svg",
            color: colors.primary,
          ),
          onPressed: () {
            CUR_USERID != null
                ? Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationList(),
                    ))
                : Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ));
          },
        ),

        _selBottom == 0
            ? Container()
            :  IconButton(
          padding: EdgeInsets.all(0),
          icon: SvgPicture.asset(
            imagePath + "desel_fav.svg",
            color: colors.primary,
          ),
          onPressed: () {
            CUR_USERID != null
                ? Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Favorite(),
                    ))
                : Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ));
          },
        ),
      ],
      backgroundColor: Theme.of(context).colorScheme.white,
    );
  }

  Widget _getBottomBar() {
    return Material(
        color: Theme.of(context).colorScheme.white,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).colorScheme.black26, blurRadius: 10)
            ],
          ),
          child: TabBar(
            onTap: (_) {
              if (_tabController.index == 3) {
                if (CUR_USERID == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ),
                  );
                  _tabController.animateTo(0);
                }
              }
            },
            controller: _tabController,
            tabs: [
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      imagePath + "desel_home.svg",
                      color: _selBottom == 0 ? colors.primary : colors.blackTemp,
                    ),
                    SizedBox(height: 3,),
                    Text(
                      "Home",
                      style: TextStyle(
                        color: _selBottom == 0 ? colors.primary : colors.black54,
                        fontSize: 9, // Adjust the font size as needed
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      imagePath + "category.svg",
                      color: _selBottom == 1 ? colors.primary : colors.blackTemp,
                    ),
                    SizedBox(height: 3,),
                    Text(
                     "Category",
                      style: TextStyle(
                        color: _selBottom == 1 ? colors.primary : colors.black54,
                        fontSize: 9, // Adjust the font size as needed
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      imagePath + "sale.svg",
                      color: _selBottom == 2 ? colors.primary : colors.blackTemp,
                    ),
                    SizedBox(height: 3,),
                    Text(
                      "Sale",
                      style: TextStyle(
                        color: _selBottom == 2 ? colors.primary : colors.black54,
                        fontSize: 9, // Adjust the font size as needed
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Selector<UserProvider, String>(
                  builder: (context, data, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Center(
                              child: SvgPicture.asset(
                                imagePath + "cart.svg",
                                color: _selBottom == 3 ? colors.primary : colors.blackTemp,
                              ),
                            ),
                            if (data != null && data.isNotEmpty && data != "0")
                              Positioned.directional(
                                bottom: _selBottom == 3 ? 6 : 20,
                                textDirection: Directionality.of(context),
                                end: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primary,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(3),
                                      child: Text(
                                        data,
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 3,),
                        Text("Cart",
                          style: TextStyle(
                            color: _selBottom == 3 ? colors.primary : colors.black54,
                            fontSize: 9, // Adjust the font size as needed
                          ),
                        ),
                      ],
                    );
                  },
                  selector: (_, homeProvider) => homeProvider.curCartCount,
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      imagePath + "profile.svg",
                      color: _selBottom == 4 ? colors.primary : colors.blackTemp,
                    ),
                    SizedBox(height: 3,),
                    Text(
                      "Account",
                      style: TextStyle(
                        color: _selBottom == 4 ? colors.primary : colors.black54,
                        fontSize: 9, // Adjust the font size as needed
                      ),
                    ),
                  ],
                ),
              ),
            ],
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: colors.primary, width: 2.0),
              insets: EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 48.0),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(3), bottomRight: Radius.circular(3)),
            ),
            indicatorColor: colors.primary,
            labelColor: colors.primary,
            unselectedLabelColor: colors.blackTemp,
            labelStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
          ),



          /* TabBar(
            onTap: (_) {
              if (_tabController.index == 3) {
                if (CUR_USERID == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ),
                  );
                  _tabController.animateTo(0);
                }
              }
            },
            controller: _tabController,
            tabs: [
              Tab(
                icon:
          //_selBottom == 0
                    // ? SvgPicture.asset(
                    //     imagePath + "sel_home.svg",
                    //     color: colors.primary,
                    //   )
                    // :
                SvgPicture.asset(
                        imagePath + "desel_home.svg",
                        color: colors.primary,
                      ),
                text:
                    _selBottom == 0 ? getTranslated(context, 'HOME_LBL',) : null,
              ),
              Tab(
                icon:
                // _selBottom == 1
                //     ? SvgPicture.asset(
                //         imagePath + "category01.svg",
                //         color: colors.primary,
                //       )
                //:
                SvgPicture.asset(
                        imagePath + "category.svg",
                        color: colors.primary,
                      ),
                text:
                    _selBottom == 1 ? getTranslated(context, 'category') : null,
              ),
              Tab(
                icon:
                // _selBottom == 2
                //     ? SvgPicture.asset(
                //         imagePath + "sale02.svg",
                //         color: colors.primary,
                //       )
                //     :
                SvgPicture.asset(
                        imagePath + "sale.svg",
                        color: colors.primary,
                      ),
                text:
                _selBottom == 2 ? getTranslated(context, 'SALE') : null,
              ),
              Tab(
                icon: Selector<UserProvider, String>(
                  builder: (context, data, child) {
                    return Stack(
                      children: [
                        Center(
                          child:
                          // _selBottom == 3
                          //     ? SvgPicture.asset(
                          //         imagePath + "cart01.svg",
                          //         color: colors.primary,
                          //       )
                          //     :
                          SvgPicture.asset(
                                  imagePath + "cart.svg",
                                  color: colors.primary,
                                ),
                        ),
                        (data != null && data.isNotEmpty && data != "0")
                            ? new Positioned.directional(
                                bottom: _selBottom == 3 ? 6 : 20,
                                textDirection: Directionality.of(context),
                                end: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.primary),
                                  child: new Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(3),
                                      child: new Text(
                                        data,
                                        style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .white),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container()
                      ],
                    );
                  },
                  selector: (_, homeProvider) => homeProvider.curCartCount,
                ),
                text: _selBottom == 3 ? getTranslated(context, 'CART') : null,
              ),
              Tab(
                icon:
                // _selBottom == 4
                //     ? SvgPicture.asset(
                //         imagePath + "profile01.svg",
                //         color: colors.primary,
                //       )
                //     :
                SvgPicture.asset(
                        imagePath + "profile.svg",
                        color: colors.primary,
                      ),
                text:
                    _selBottom == 4 ? getTranslated(context, 'ACCOUNT') : null,
              ),
            ],
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: colors.primary, width: 5.0),
              insets: EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 70.0),
            ),
              indicatorColor: colors.primary,
            labelColor: colors.primary,
            labelStyle: TextStyle(fontSize: 8 , fontWeight: FontWeight.w600),
          ),*/
        ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
