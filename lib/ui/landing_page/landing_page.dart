import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:oxidized/oxidized.dart';
import 'package:paintroid/core/toast_utils.dart';
import 'package:paintroid/data/model/project.dart';
import 'package:paintroid/data/project_database.dart';
import 'package:paintroid/io/io.dart';
import 'package:paintroid/ui/color_schemes.dart';
import 'package:paintroid/ui/io_handler.dart';
import 'package:paintroid/ui/landing_page/custom_action_button.dart';
import 'package:paintroid/ui/landing_page/image_preview.dart';
import 'package:paintroid/ui/landing_page/main_overflow_menu.dart';
import 'package:paintroid/ui/landing_page/project_list_tile.dart';
import 'package:paintroid/ui/landing_page/project_overflow_menu.dart';
import 'package:paintroid/workspace/src/state/canvas/canvas_state_provider.dart';
import 'package:paintroid/workspace/src/state/workspace_state_notifier.dart';
import 'package:toast/toast.dart';

class LandingPage extends ConsumerStatefulWidget {
  final String title;

  const LandingPage({Key? key, required this.title}) : super(key: key);

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  late ProjectDatabase database;
  late IFileService fileService;
  late IImageService imageService;

  Future<List<Project>> _getProjects() async =>
      database.projectDAO.getProjects();

  Future<void> _navigateToPocketPaint() async {
    await Navigator.pushNamed(context, '/PocketPaint');
    setState(() {});
  }

  Future<bool> _loadProject(IOHandler ioHandler, Project project) async {
    project.lastModified = DateTime.now();
    await database.projectDAO.insertProject(project);
    return fileService.getFile(project.path).when(
      ok: (file) async {
        return await ioHandler.loadFromFiles(Result.ok(file));
      },
      err: (failure) {
        if (failure != LoadImageFailure.userCancelled) {
          ToastUtils.showShortToast(message: failure.message);
        }
        return false;
      },
    );
  }

  void _clearCanvas() {
    ref.read(canvasStateProvider.notifier)
      ..clearBackgroundImageAndResetDimensions()
      ..resetCanvasWithNewCommands([]);
    ref.read(WorkspaceState.provider.notifier).updateLastSavedCommandCount();
  }

  Future<void> _openProject(Project? project, IOHandler ioHandler) async {
    if (project != null) {
      bool loaded = await _loadProject(ioHandler, project);
      if (loaded) _navigateToPocketPaint();
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);

    final db = ref.watch(ProjectDatabase.provider);
    db.when(
      data: (value) => database = value,
      error: (err, stacktrace) =>
          ToastUtils.showShortToast(message: 'Error: $err'),
      loading: () {},
    );
    final ioHandler = ref.watch(IOHandler.provider);
    Project? latestModifiedProject;
    fileService = ref.watch(IFileService.provider);
    imageService = ref.watch(IImageService.provider);

    return Scaffold(
      backgroundColor: lightColorScheme.primary,
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [MainOverflowMenu()],
      ),
      body: FutureBuilder(
        future: _getProjects(),
        builder: (BuildContext context, AsyncSnapshot<List<Project>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            if (snapshot.data!.isNotEmpty) {
              latestModifiedProject = snapshot.data![0];
            }
            return Column(
              children: [
                Flexible(
                  flex: 2,
                  child: _ProjectPreview(
                    ioHandler: ioHandler,
                    imageService: imageService,
                    latestModifiedProject: latestModifiedProject,
                    openProject: () =>
                        _openProject(latestModifiedProject, ioHandler),
                  ),
                ),
                Container(
                  color: lightColorScheme.primaryContainer,
                  padding: const EdgeInsets.all(20),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Projects',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      if (index != 0) {
                        Project project = snapshot.data![index];
                        return ProjectListTile(
                          project: project,
                          imageService: imageService,
                          index: index,
                          onTap: () async => _openProject(project, ioHandler),
                        );
                      }
                      return Container();
                    },
                    itemCount: snapshot.data?.length,
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: lightColorScheme.background,
              ),
            );
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomActionButton(
            heroTag: 'import_image',
            icon: Icons.file_download,
            hint: 'Load image',
            onPressed: () async {
              final bool imageLoaded =
                  await ioHandler.loadImage(context, this, false);
              if (imageLoaded && mounted) {
                _navigateToPocketPaint();
              }
            },
          ),
          const SizedBox(
            height: 10,
          ),
          CustomActionButton(
            heroTag: 'new_image',
            icon: Icons.add,
            hint: 'New image',
            onPressed: () async {
              _clearCanvas();
              _navigateToPocketPaint();
            },
          ),
        ],
      ),
    );
  }
}

class _ProjectPreview extends StatelessWidget {
  final Project? latestModifiedProject;
  final IOHandler ioHandler;
  final IImageService imageService;
  final VoidCallback openProject;

  const _ProjectPreview({
    this.latestModifiedProject,
    required this.ioHandler,
    required this.imageService,
    required this.openProject,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          child: InkWell(
            onTap: openProject,
            child: ImagePreview(
              project: latestModifiedProject,
              imageService: imageService,
              color: Colors.white54,
            ),
          ),
        ),
        Center(
          child: IconButton(
            key: const Key('myEditIcon'),
            iconSize: 264,
            onPressed: () async {
              if (latestModifiedProject != null) {
                openProject();
              }
            },
            icon: SvgPicture.asset(
              'assets/svg/ic_edit_circle.svg',
              height: 264,
              width: 264,
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.topEnd,
          child: latestModifiedProject == null
              ? null
              : ProjectOverflowMenu(
                  key: const Key('ProjectOverflowMenu Key0'),
                  project: latestModifiedProject!,
                ),
        ),
      ],
    );
  }
}
