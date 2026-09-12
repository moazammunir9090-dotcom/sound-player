import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sound_item.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/motion.dart';
import '../utils/responsive.dart';
import '../widgets/album_art.dart';
import '../widgets/animated_background.dart';
import '../widgets/equalizer_bars.dart';
import '../widgets/press_scale.dart';
import '../widgets/screen_header.dart';
import '../widgets/soft_card.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/waveform.dart';

/// A four-step wizard for adding a sound to the library.
///
/// Every step is a page of one form, so the shell here owns the state and the
/// steps stay presentational. Nothing is written to the library until the last
/// step confirms — which is what makes "Back" safe to press at any point.
class AddSoundScreen extends StatefulWidget {
  const AddSoundScreen({super.key});

  @override
  State<AddSoundScreen> createState() => _AddSoundScreenState();
}

class _AddSoundScreenState extends State<AddSoundScreen>
    with TickerProviderStateMixin {
  static const List<String> _stepLabels = <String>[
    'Source',
    'Details',
    'Trim',
    'Review',
  ];

  int _step = 0;

  /// Which way the last transition went, so the slide matches the direction.
  bool _forward = true;

  // ------------------------------------------------------------ form state
  SoundSource _source = SoundSource.file;
  final TextEditingController _title = TextEditingController();
  final TextEditingController _artist = TextEditingController();
  final TextEditingController _collection = TextEditingController();
  final TextEditingController _link = TextEditingController();

  String _category = 'Focus';
  int _artSeed = 0;
  double _trimStart = .06;
  double _trimEnd = .94;
  Duration _duration = const Duration(minutes: 3, seconds: 24);
  String? _pickedFileName;
  String? _titleError;

  // ---------------------------------------------------------- record state
  bool _recording = false;
  Timer? _recordTimer;
  Duration _recorded = Duration.zero;

  // ----------------------------------------------------------- save state
  bool _saving = false;
  bool _saved = false;

  late final AnimationController _check = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  static const List<String> _categories = <String>[
    'Focus',
    'Ambient',
    'Beats',
    'Nature',
    'Sleep',
    'Podcast',
  ];

  @override
  void dispose() {
    _recordTimer?.cancel();
    _title.dispose();
    _artist.dispose();
    _collection.dispose();
    _link.dispose();
    _check.dispose();
    _shake.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------- helpers

  String get _effectiveTitle {
    if (_title.text.trim().isNotEmpty) return _title.text.trim();
    if (_pickedFileName != null) {
      // Fall back to the file name, minus its extension.
      final name = _pickedFileName!;
      final dot = name.lastIndexOf('.');
      return dot > 0 ? name.substring(0, dot) : name;
    }
    if (_source == SoundSource.recording && _recorded > Duration.zero) {
      return 'Recording ${_recorded.inMinutes + 1}';
    }
    if (_source == SoundSource.link && _link.text.trim().isNotEmpty) {
      final uri = Uri.tryParse(_link.text.trim());
      final last = uri?.pathSegments.isNotEmpty == true
          ? uri!.pathSegments.last
          : '';
      if (last.isNotEmpty) return last;
    }
    return 'Untitled sound';
  }

  /// Length of the selection made on the Trim step.
  Duration get _trimmedDuration => Duration(
    milliseconds: (_duration.inMilliseconds * (_trimEnd - _trimStart)).round(),
  );

  void _goTo(int step) {
    if (step == _step || step < 0 || step >= _stepLabels.length) return;
    setState(() {
      _forward = step > _step;
      _step = step;
    });
  }

  void _next() {
    if (_step == 1 && _title.text.trim().isEmpty && _pickedFileName == null) {
      // Only the Details step has a hard requirement, and only when there is
      // nothing to fall back on.
      setState(() => _titleError = 'Give this sound a name to continue');
      _shake.forward(from: 0);
      tapFeedback(context, strong: true);
      return;
    }
    if (_step == _stepLabels.length - 1) {
      _save();
      return;
    }
    _goTo(_step + 1);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _goTo(_step - 1);
  }

  void _toggleRecording() {
    if (_recording) {
      _recordTimer?.cancel();
      setState(() => _recording = false);
      if (_recorded > Duration.zero) _duration = _recorded;
      return;
    }
    setState(() {
      _recording = true;
      _recorded = Duration.zero;
    });
    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _recorded += const Duration(milliseconds: 100));
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    // A short beat so the "Saving" state is actually visible; there is no I/O
    // to wait on in this project.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    AppScope.of(context).addSound(
      SoundItem(
        id: 'user-${DateTime.now().microsecondsSinceEpoch}',
        title: _effectiveTitle,
        artist: _artist.text.trim().isEmpty ? 'You' : _artist.text.trim(),
        collection: _collection.text.trim().isEmpty
            ? 'My uploads'
            : _collection.text.trim(),
        duration: _trimmedDuration,
        seed: _artSeed,
        category: _category,
        source: _source,
        addedAt: DateTime.now(),
      ),
    );

    setState(() {
      _saving = false;
      _saved = true;
    });
    _check.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        intensity: .7,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  ScreenHeader(
                    title: 'Add sound',
                    subtitle: _stepLabels[_step],
                    onBack: _saved ? null : _back,
                  ),
                  _StepIndicator(
                    labels: _stepLabels,
                    current: _step,
                    onTap: _saved ? null : _goTo,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ScrollablePage(
                      center: false,
                      maxWidth: Responsive.formWidth,
                      children: [
                        // Direction-aware step transition.
                        AnimatedSwitcher(
                          duration: motionDuration(
                            context,
                            const Duration(milliseconds: 400),
                          ),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final incoming =
                                child.key == ValueKey<int>(_step);
                            final begin = Offset(
                              _forward
                                  ? (incoming ? .12 : -.08)
                                  : (incoming ? -.12 : .08),
                              0,
                            );
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: begin,
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey<int>(_step),
                            child: _buildStep(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  _FooterBar(
                    step: _step,
                    lastStep: _stepLabels.length - 1,
                    saving: _saving,
                    saved: _saved,
                    onBack: _back,
                    onNext: _next,
                  ),
                ],
              ),
              // Success overlay sits above everything and fades the form out.
              if (_saved)
                Positioned.fill(
                  child: _SuccessOverlay(
                    animation: _check,
                    title: _effectiveTitle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _SourceStep(
          source: _source,
          onSource: (s) => setState(() => _source = s),
          fileName: _pickedFileName,
          onPickFile: () => setState(
            () => _pickedFileName ??= 'field-recording-04.wav',
          ),
          recording: _recording,
          recorded: _recorded,
          onToggleRecording: _toggleRecording,
          linkController: _link,
        );
      case 1:
        return _DetailsStep(
          titleController: _title,
          artistController: _artist,
          collectionController: _collection,
          category: _category,
          categories: _categories,
          onCategory: (c) => setState(() => _category = c),
          error: _titleError,
          shake: _shake,
          onTitleChanged: () {
            if (_titleError != null) setState(() => _titleError = null);
          },
        );
      case 2:
        return _TrimStep(
          seed: _artSeed,
          artSeed: _artSeed,
          onArtSeed: (v) => setState(() => _artSeed = v),
          duration: _duration,
          start: _trimStart,
          end: _trimEnd,
          onChanged: (s, e) => setState(() {
            _trimStart = s;
            _trimEnd = e;
          }),
          trimmed: _trimmedDuration,
        );
      default:
        return _ReviewStep(
          title: _effectiveTitle,
          artist: _artist.text.trim().isEmpty ? 'You' : _artist.text.trim(),
          collection: _collection.text.trim().isEmpty
              ? 'My uploads'
              : _collection.text.trim(),
          category: _category,
          source: _source,
          seed: _artSeed,
          duration: _trimmedDuration,
          trimStart: _trimStart,
        );
    }
  }
}

// ------------------------------------------------------------ step indicator

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.labels,
    required this.current,
    this.onTap,
  });

  final List<String> labels;
  final int current;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.gutter(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: PressScale(
                    onTap: onTap == null || i > current
                        ? null
                        : () => onTap!(i),
                    scale: .97,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: motionDuration(
                            context,
                            const Duration(milliseconds: 340),
                          ),
                          curve: Curves.easeOutCubic,
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            // Everything up to and including the current step
                            // is filled; the rest stays a track.
                            gradient: i <= current
                                ? palette.brandGradient
                                : null,
                            color: i <= current ? null : palette.surfaceSunken,
                          ),
                        ),
                        const SizedBox(height: 7),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style:
                              (i == current
                                      ? theme.textTheme.labelSmall?.copyWith(
                                          color: palette.orange,
                                          letterSpacing: .6,
                                        )
                                      : theme.textTheme.labelSmall?.copyWith(
                                          color: palette.textFaint,
                                          letterSpacing: .6,
                                        )) ??
                              const TextStyle(),
                          child: Text(
                            labels[i].toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- step 1

class _SourceStep extends StatelessWidget {
  const _SourceStep({
    required this.source,
    required this.onSource,
    required this.fileName,
    required this.onPickFile,
    required this.recording,
    required this.recorded,
    required this.onToggleRecording,
    required this.linkController,
  });

  final SoundSource source;
  final ValueChanged<SoundSource> onSource;
  final String? fileName;
  final VoidCallback onPickFile;
  final bool recording;
  final Duration recorded;
  final VoidCallback onToggleRecording;
  final TextEditingController linkController;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < SoundSource.values.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StaggeredEntrance(
              index: i,
              child: _SourceCard(
                source: SoundSource.values[i],
                selected: source == SoundSource.values[i],
                onTap: () => onSource(SoundSource.values[i]),
              ),
            ),
          ),
        const SizedBox(height: 6),
        // The panel below changes with the chosen source.
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
            child: switch (source) {
              SoundSource.file => _FilePanel(
                key: const ValueKey('file'),
                fileName: fileName,
                onPick: onPickFile,
              ),
              SoundSource.recording => _RecordPanel(
                key: const ValueKey('record'),
                recording: recording,
                recorded: recorded,
                onToggle: onToggleRecording,
              ),
              SoundSource.link => _LinkPanel(
                key: const ValueKey('link'),
                controller: linkController,
              ),
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: palette.textFaint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nothing is uploaded anywhere — this is a front-end '
                'prototype, so your sound stays on the device.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textFaint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.selected,
    required this.onTap,
  });

  final SoundSource source;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final icon = switch (source) {
      SoundSource.file => Icons.folder_open_rounded,
      SoundSource.recording => Icons.mic_rounded,
      SoundSource.link => Icons.link_rounded,
    };

    return PressScale(
      onTap: onTap,
      scale: .98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? palette.orangeWash : palette.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: selected ? palette.orange : palette.divider,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? palette.lift(blur: 22, y: 10, alpha: .16)
              : const <BoxShadow>[],
        ),
        child: Row(
          children: [
            IconTile(
              icon: icon,
              size: 46,
              iconSize: 21,
              gradient: selected,
              color: palette.orange,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    source.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    source.blurb,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // A radio that fills with the sweep as it is chosen.
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected ? palette.brandGradient : null,
                border: Border.all(
                  color: selected ? Colors.transparent : palette.divider,
                  width: 1.6,
                ),
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                scale: selected ? 1 : 0,
                child: const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePanel extends StatelessWidget {
  const _FilePanel({super.key, required this.fileName, required this.onPick});

  final String? fileName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final picked = fileName != null;

    return SoftCard(
      onTap: onPick,
      borderColor: picked ? palette.orange.withValues(alpha: .4) : palette.divider,
      color: picked ? palette.orangeWash : palette.surfaceAlt,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Icon(
              picked
                  ? Icons.audio_file_rounded
                  : Icons.cloud_upload_outlined,
              key: ValueKey(picked),
              size: 26,
              color: picked ? palette.orangeInk : palette.textFaint,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  picked ? fileName! : 'Tap to choose a file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  picked ? 'Ready to import' : 'WAV, MP3, FLAC or M4A',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textFaint,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: picked ? palette.orange : palette.textFaint,
          ),
        ],
      ),
    );
  }
}

class _RecordPanel extends StatelessWidget {
  const _RecordPanel({
    super.key,
    required this.recording,
    required this.recorded,
    required this.onToggle,
  });

  final bool recording;
  final Duration recorded;
  final VoidCallback onToggle;

  String get _label {
    final m = recorded.inMinutes.toString().padLeft(2, '0');
    final s = (recorded.inSeconds % 60).toString().padLeft(2, '0');
    final tenths = (recorded.inMilliseconds % 1000) ~/ 100;
    return '$m:$s.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SoftCard(
      child: Row(
        children: [
          PressScale(
            onTap: onToggle,
            scale: .9,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: recording ? null : palette.brandGradient,
                color: recording ? palette.danger : null,
                boxShadow: palette.lift(blur: 18, y: 8, alpha: .24),
              ),
              child: Icon(
                recording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (recording) ...[
                      PulsingDot(
                        size: 8,
                        spread: 3,
                        color: palette.danger,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      recording ? 'Recording' : 'Ready to record',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recording)
                  EqualizerBars(
                    barCount: 16,
                    height: 22,
                    barWidth: 3,
                    gap: 3,
                    minFactor: .15,
                  )
                else
                  Text(
                    'Tap the microphone and Sonora will capture the room.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textFaint,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: recording ? palette.danger : palette.textFaint,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkPanel extends StatelessWidget {
  const _LinkPanel({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const FieldLabel('Source URL'),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://example.com/track.mp3',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: palette.textFaint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The link is only stored on the item — nothing is fetched.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textFaint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- step 2

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.titleController,
    required this.artistController,
    required this.collectionController,
    required this.category,
    required this.categories,
    required this.onCategory,
    required this.error,
    required this.shake,
    required this.onTitleChanged,
  });

  final TextEditingController titleController;
  final TextEditingController artistController;
  final TextEditingController collectionController;
  final String category;
  final List<String> categories;
  final ValueChanged<String> onCategory;
  final String? error;
  final Animation<double> shake;
  final VoidCallback onTitleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StaggeredEntrance(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FieldLabel('Title'),
              // The shake is a horizontal wobble around the field, used when
              // the step is submitted without a name.
              AnimatedBuilder(
                animation: shake,
                builder: (context, child) {
                  final t = shake.value;
                  final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onTitleChanged(),
                  decoration: InputDecoration(
                    hintText: 'e.g. Midnight Drive',
                    prefixIcon: const Icon(Icons.music_note_rounded),
                    errorText: error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        StaggeredEntrance(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FieldLabel('Artist'),
              TextField(
                controller: artistController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Leave blank to credit yourself',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        StaggeredEntrance(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FieldLabel('Collection'),
              TextField(
                controller: collectionController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Album or playlist',
                  prefixIcon: Icon(Icons.album_outlined),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        StaggeredEntrance(
          index: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FieldLabel('Category'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories)
                    _CategoryChip(
                      label: c,
                      selected: c == category,
                      onTap: () => onCategory(c),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'A category keeps the library filters useful once it fills up.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textFaint,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return PressScale(
      onTap: onTap,
      scale: .94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? palette.brandGradient : null,
          color: selected ? null : palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : palette.divider,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : palette.textSecondary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- step 3

class _TrimStep extends StatelessWidget {
  const _TrimStep({
    required this.seed,
    required this.artSeed,
    required this.onArtSeed,
    required this.duration,
    required this.start,
    required this.end,
    required this.onChanged,
    required this.trimmed,
  });

  final int seed;
  final int artSeed;
  final ValueChanged<int> onArtSeed;
  final Duration duration;
  final double start;
  final double end;
  final void Function(double, double) onChanged;
  final Duration trimmed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StaggeredEntrance(
          index: 0,
          child: SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FieldLabel('Trim'),
                Text(
                  'Drag either handle to choose what plays.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textFaint,
                  ),
                ),
                const SizedBox(height: 14),
                WaveformTrim(
                  seed: seed,
                  start: start,
                  end: end,
                  onChanged: onChanged,
                  height: 92,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _TimePill(
                      label: 'Start',
                      value: _timeOf(start),
                      color: palette.orange,
                    ),
                    const Spacer(),
                    _TimePill(
                      label: 'Length',
                      value: formatDuration(trimmed),
                      color: palette.blue,
                    ),
                    const Spacer(),
                    _TimePill(
                      label: 'End',
                      value: _timeOf(end),
                      color: palette.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        StaggeredEntrance(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FieldLabel('Artwork'),
              Text(
                'Generated from a gradient — pick the one you like.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textFaint,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 8,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => PressScale(
                    onTap: () => onArtSeed(i),
                    scale: .92,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: artSeed == i
                              ? palette.orange
                              : Colors.transparent,
                          width: 2.2,
                        ),
                      ),
                      child: AlbumArt(seed: i, size: 62, radius: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _timeOf(double fraction) => formatDuration(
    Duration(milliseconds: (duration.inMilliseconds * fraction).round()),
  );
}

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textFaint,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- step 4

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.title,
    required this.artist,
    required this.collection,
    required this.category,
    required this.source,
    required this.seed,
    required this.duration,
    required this.trimStart,
  });

  final String title;
  final String artist;
  final String collection;
  final String category;
  final SoundSource source;
  final int seed;
  final Duration duration;
  final double trimStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StaggeredEntrance(
          index: 0,
          child: SoftCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ReplayOnArtSeed(
                  seed: seed,
                  child: AlbumArt(seed: seed, size: 84, radius: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$artist · $collection',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textFaint,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Badge(label: category, color: palette.orange),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _Badge(
                              label: formatDuration(duration),
                              color: palette.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        StaggeredEntrance(
          index: 1,
          child: SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DetailRow(
                  label: 'Source',
                  value: source.label,
                  icon: Icons.input_rounded,
                ),
                Divider(height: 1, color: palette.divider),
                DetailRow(
                  label: 'Starts at',
                  value: '${(trimStart * 100).round()}% in',
                  icon: Icons.content_cut_rounded,
                ),
                Divider(height: 1, color: palette.divider),
                DetailRow(
                  label: 'Plays for',
                  value: formatDuration(duration),
                  icon: Icons.schedule_rounded,
                ),
                Divider(height: 1, color: palette.divider),
                DetailRow(
                  label: 'Stored',
                  value: 'On this device',
                  valueColor: palette.success,
                  icon: Icons.smartphone_rounded,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: palette.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ready to add. You can edit any of this later.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textFaint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small animated pop when the artwork seed changes, so the review card
/// acknowledges the new cover.
class ReplayOnArtSeed extends StatefulWidget {
  const ReplayOnArtSeed({super.key, required this.seed, required this.child});

  final int seed;
  final Widget child;

  @override
  State<ReplayOnArtSeed> createState() => _ReplayOnArtSeedState();
}

class _ReplayOnArtSeedState extends State<ReplayOnArtSeed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );

  @override
  void didUpdateWidget(ReplayOnArtSeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0));
        return Transform.rotate(
          angle: (1 - _c.value) * -.12,
          child: Transform.scale(scale: .86 + .14 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- footer

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.step,
    required this.lastStep,
    required this.saving,
    required this.saved,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int lastStep;
  final bool saving;
  final bool saved;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final gutter = Responsive.gutter(context);
    final isLast = step == lastStep;
    final compact = Responsive.isCompact(context);

    final back = OutlinedButton(
      onPressed: saved ? null : onBack,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22),
      ),
      child: Text(step == 0 ? 'Cancel' : 'Back'),
    );

    final next = BrandButton(
      label: isLast ? 'Add to library' : 'Continue',
      onTap: saved ? null : onNext,
      loading: saving,
      trailingArrow: !isLast,
      icon: isLast ? Icons.add_rounded : null,
      expand: true,
      height: 54,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 10),
      child: compact
          ? Row(
              children: [
                back,
                const SizedBox(width: 12),
                Expanded(child: next),
              ],
            )
          : ReadableWidth(
              maxWidth: Responsive.formWidth,
              child: Row(
                children: [
                  back,
                  const SizedBox(width: 12),
                  Expanded(child: next),
                ],
              ),
            ),
    );
  }
}

// ------------------------------------------------------------------ success

/// Full-bleed confirmation shown for a beat before the screen pops.
class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay({required this.animation, required this.title});

  final Animation<double> animation;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return ColoredBox(
          color: palette.background.withValues(alpha: .92 * t.clamp(0, 1)),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 108,
                  child: CustomPaint(
                    painter: _CheckPainter(
                      progress: Curves.easeOutCubic.transform(t),
                      ring: palette.surfaceSunken,
                      gradient: palette.brandGradient,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: ((t - .45) / .35).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Added to your library',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({
    required this.progress,
    required this.ring,
    required this.gradient,
  });

  final double progress;
  final Color ring;
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, Paint()..color = ring);

    // Ring draws first (0 -> 0.55), then the tick (0.45 -> 1).
    final ringT = (progress / .55).clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * ringT,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect),
    );

    final checkT = ((progress - .45) / .55).clamp(0.0, 1.0);
    if (checkT <= 0) return;

    // The tick is drawn by walking a PathMetric, which is what makes it look
    // hand-drawn rather than scaled in.
    final path = Path()
      ..moveTo(center.dx - radius * .38, center.dy + radius * .02)
      ..lineTo(center.dx - radius * .10, center.dy + radius * .30)
      ..lineTo(center.dx + radius * .40, center.dy - radius * .30);

    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * checkT),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.ring != ring;
}
