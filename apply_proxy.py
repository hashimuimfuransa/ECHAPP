import os, re

# (file, [(old_fragment, new_fragment), ...])
# Each old fragment must exist exactly once in the file.

edits = {
    'frontend/lib/presentation/screens/admin/admin_dashboard_screen.dart': [
        ("NetworkImage(user.profilePicture!)", "NetworkImage(mediaProxyUrl(user.profilePicture))"),
    ],
    'frontend/lib/presentation/screens/admin/admin_teachers_screen.dart': [
        ("child: Image.network(\n                                    course.thumbnail!,", "child: Image.network(\n                                    mediaProxyUrl(course.thumbnail),"),
    ],
    'frontend/lib/presentation/screens/admin/course_analytics_screen.dart': [
        ("NetworkImage(_analytics!.course['thumbnail'])", "NetworkImage(mediaProxyUrl(_analytics!.course['thumbnail']))"),
    ],
    'frontend/lib/presentation/screens/learning/professional_learning_screen.dart': [
        ("Image.network(\n                 _course!.thumbnail!,", "Image.network(\n                 mediaProxyUrl(_course!.thumbnail),"),
        ("child: Image.network(\n                   coverUrl,", "child: Image.network(\n                   mediaProxyUrl(coverUrl),"),
    ],
    'frontend/lib/widgets/ai_chat_message_widget.dart': [
        ("? Image.network(\n                 attachPath,", "? Image.network(\n                 mediaProxyUrl(attachPath),"),
    ],
    'frontend/lib/presentation/screens/dashboard/dashboard_screen_backup.dart': [
        ("? Image.network(\n                                       course.thumbnail!,", "? Image.network(\n                                       mediaProxyUrl(course.thumbnail),"),
        ("? Image.network(\n                         course.thumbnail!,", "? Image.network(\n                         mediaProxyUrl(course.thumbnail),"),
        ("? Image.network(\n                         course.thumbnail!,", "? Image.network(\n                         mediaProxyUrl(course.thumbnail),"),
        ("image: NetworkImage(course.thumbnail!),", "image: NetworkImage(mediaProxyUrl(course.thumbnail)),"),
    ],
    'frontend/lib/presentation/screens/library/library_screen.dart': [
        ("imageUrl: book.coverUrl!,", "imageUrl: mediaProxyUrl(book.coverUrl),"),
        ("imageUrl: book['coverUrl'],", "imageUrl: mediaProxyUrl(book['coverUrl']),"),
    ],
    'frontend/lib/widgets/responsive_navigation_drawer.dart': [
        ("NetworkImage(user.profilePicture!)", "NetworkImage(mediaProxyUrl(user.profilePicture))"),
    ],
    'frontend/lib/widgets/course_card_example.dart': [
        ("child: Image.network(\n                       course.imageUrl!,", "child: Image.network(\n                       mediaProxyUrl(course.imageUrl),"),
        ("child: Image.network(\n                     course.imageUrl!,", "child: Image.network(\n                     mediaProxyUrl(course.imageUrl),"),
    ],
}

for path, pairs in edits.items():
    if not os.path.exists(path):
        print(f"MISSING FILE: {path}")
        continue
    s = open(path, encoding='utf-8').read()
    orig = s
    for old, new in pairs:
        if old in s:
            s = s.replace(old, new, 1)
        else:
            print(f"  NOT FOUND in {path}: {old!r}")
    if s != orig:
        open(path, 'w', encoding='utf-8', newline='').write(s)
        print(f"UPDATED: {path}")
