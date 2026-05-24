import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		// Override point for customization after application launch.
		UTMViewControllerPatches.patchAll()
		return true
	}

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration
	{
		let role = connectingSceneSession.role
		if #available(iOS 16.0, *), role == .windowExternalDisplayNonInteractive {
			return UISceneConfiguration(name: "External Display Configuration", sessionRole: role)
		}
		return UISceneConfiguration(name: "Default Configuration", sessionRole: role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>)
	{
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}

	func applicationWillTerminate(_ application: UIApplication)
	{
		CParsec.destroy()
	}
}
