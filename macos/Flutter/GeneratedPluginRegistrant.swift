//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import cloud_functions
import firebase_auth
import firebase_core
import package_info_plus
import printing
import share_plus

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FirebaseFunctionsPlugin.register(with: registry.registrar(forPlugin: "FirebaseFunctionsPlugin"))
  FLTFirebaseAuthPlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseAuthPlugin"))
  FLTFirebaseCorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCorePlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  PrintingPlugin.register(with: registry.registrar(forPlugin: "PrintingPlugin"))
  SharePlusMacosPlugin.register(with: registry.registrar(forPlugin: "SharePlusMacosPlugin"))
}
