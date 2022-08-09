import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:bus_tracker_aw/models/announcment.dart';
import 'package:bus_tracker_aw/screens/student/ann-details-page.dart';
import 'package:flutter/cupertino.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../general.dart';

class AnnouncementPage extends StatefulWidget {
  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late Database _database;
  Future? _futureAnn;

  @override
  void initState() {
    super.initState();
    _database = Database(CurrentSession.client);
    setAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        FutureBuilder(
          future: _futureAnn,
          builder: ((context, snapshot) {
            List<Widget> children;
            if (snapshot.hasData) {
              DocumentList _announcementList = snapshot.data as DocumentList;
              List<Announcement> _reports =
                  announcementsFromJson(_announcementList);
              if (_announcementList.documents.isNotEmpty) {
                children = <Widget>[
                  Expanded(
                    child: SmartRefresher(
                      enablePullDown: true,
                      enablePullUp: false,
                      header: const ClassicHeader(),
                      controller: _refreshController,
                      onRefresh: _onRefresh,
                      onLoading: _onLoading,
                      child: ListView.builder(
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.info),
                                  title: Text(_reports[index].title!),
                                  trailing: Text(
                                      "${_reports[index].dateCreated!.day.toString()} / ${_reports[index].dateCreated!.month.toString()} / ${_reports[index].dateCreated!.year.toString()} "),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AnnDetailsPage(
                                                announcement: _reports[index],
                                              )),
                                    );
                                  },
                                ),
                                const Divider(
                                  height: 1,
                                  color: Colors.grey,
                                )
                              ],
                            );
                          }),
                    ),
                  )
                ];
              } else {
                print("has no data");
                children = <Widget>[
                  SvgPicture.asset(
                    'assets/svgs/no_data.svg',
                    width: MediaQuery.of(context).size.width / 3,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 30),
                    child: const Text(
                      "No Announcements",
                      style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey),
                      textAlign: TextAlign.center,
                    ),
                  )
                ];
              }
            } else if (snapshot.hasError) {
              children = <Widget>[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 1.25,
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.left,
                  ),
                )
              ];
            } else {
              children = const <Widget>[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Loading...'),
                )
              ];
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            );
          }),
        ),
        /*Container(
          margin: const EdgeInsets.all(10),
          child: FloatingActionButton(
            elevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange,
            child: const Icon(Icons.date_range_outlined),
            onPressed: () {
              showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now());
            },
          ),
        ),*/
      ],
    );
  }

  Future<void> setAnnouncements() async {
    Future result = _database.listDocuments(
      collectionId: 'announcements',
    );

    setState(() {
      _futureAnn = result;
    });
  }

  void _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    await setAnnouncements();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await setAnnouncements();
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }
}
