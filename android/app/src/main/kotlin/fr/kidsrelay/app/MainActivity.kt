package fr.kidsrelay.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity et non FlutterActivity : `local_auth` a
// besoin d'une activite compatible AndroidX Fragment pour afficher la
// demande de deverrouillage. Avec FlutterActivity, la demande echoue et
// le parent reste devant un ecran verrouille sans comprendre pourquoi.
class MainActivity : FlutterFragmentActivity()
