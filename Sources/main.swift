// The Swift Programming Language
// https://docs.swift.org/swift-book

import Alamofire
import Foundation
import SwiftSoup
import SwiftTUI

enum Status {
    case pending
    case loading
    case error
}

struct MyTerminalView: View {
    @State private var torrentLinks: [String] = []
    @State private var magnetLink: String?
    @State private var search: String = "" // maybe wont use use
    @State private var output: String = ""

    var body: some View {
        VStack {
            var status = Status.pending
            HStack {
                Text("What would you like to search for?!")
                TextField { input in
                    search = input
                    print("\n new log: \(search)")
                    fetchHTML(from: "https://1337x.to/search/\(search)/1/") { result in
                        switch result {
                        case let .success(html):
                            torrentLinks = parseHTML(html, searchTerm: search)
                        case let .failure(error):
                            print("Error fetching HTML: \(error)")
                        }
                    }
                }
            }

            ForEach(torrentLinks, id: \.self) { link in
                Button(link) {
                    output = ""
                    fetchTorrentFileLink(from: link) { result in
                        if let torrentLink = result {
                            output = downloadTorrentFile(from: torrentLink)
                            openFile()

                        } else {
                            print("No torrent link found.")
                        }
                    }
                }
            }
            Text("Downloading")
            Text("Download Status: \(output)")

            Spacer()
        }
    }
}

@main
struct MyApp {
    static func main() {
        Application(rootView: MyTerminalView()).start()
    }
}

func fetchHTML(from url: String, completion: @escaping (Result<String, Error>) -> Void) {
    print("fetch html")
    AF.request(url).responseString { response in
        switch response.result {
        case let .success(html):
            print("success")
            completion(.success(html))
        case let .failure(error):
            print("fail")
            completion(.failure(error))
        }
    }
}

func parseHTML(_ html: String, searchTerm _: String) -> [String] {
    var torrentLinks: [String] = []
    do {
        let document = try SwiftSoup.parse(html)
        let rows = try document.select("tbody tr")

        for row in rows {
            let cells = try row.select("td")
            for cell in cells {
                if try cell.hasClass("coll-1 name") { // Target the correct cell
                    let links = try cell.select("a[href]") // Select all <a> tags with href attribute
                    for link in links {
                        if try !link.hasClass("icon") { // Exclude the <a> tag with class "icon"
                            let href = try link.attr("href")
                            let torrentLink = "https://1337x.to\(href)"
                            torrentLinks.append(torrentLink)
                        }
                    }
                }
            }
        }
    } catch {
        print("Error parsing HTML: \(error)")
    }
    return torrentLinks
}

func downloadMagnetLink(_ magnetLink: String) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["transmission-remote", "--add", magnetLink]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    // print("Command output: \(output)")
    print("Task terminated with status: \(task.terminationStatus)")

    // Optionally add a command to refresh Transmission
    let refreshTask = Process()
    refreshTask.launchPath = "/usr/bin/env"
    refreshTask.arguments = ["transmission-remote", "--list"] // This may trigger a refresh
    refreshTask.launch()
    refreshTask.waitUntilExit()
    return task.terminationStatus
}

func fetchTorrentFileLink(from url: String, completion: @escaping (String?) -> Void) {
    AF.request(url).responseString { response in
        switch response.result {
        case let .success(html):
            do {
                let document = try SwiftSoup.parse(html)
                if let dropdownMenu = try document.select("ul.dropdown-menu").first() {
                    // Find all links within the dropdown menu
                    let torrentLinks = try dropdownMenu.select("a[href$=.torrent]")
                    if let torrentLink = try torrentLinks.first()?.attr("href") {
                        // print("torrent link \(torrentLink)")
                        completion(torrentLink)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing HTML: \(error)")
                completion(nil)
            }
        case let .failure(error):
            print("Error fetching URL: \(error)")
            completion(nil)
        }
    }
}

func downloadTorrentFile(from link: String) -> String {
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
    let downloadPath = "\(homeDirectory)/Downloads/torrent_file.torrent"

    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["curl", "-L", "-o", downloadPath, link]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    // print("Download output: \(output)")
    return output
}

func openFile() {
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
    let downloadPath = "\(homeDirectory)/Downloads/torrent_file.torrent"

    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["open", downloadPath]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()
    task.waitUntilExit()
}

func fetchAndSimulateButtonClick(from url: String, completion: @escaping (String?) -> Void) {
    AF.request(url).responseString { response in
        switch response.result {
        case let .success(html):
            do {
                let document = try SwiftSoup.parse(html)
                if let linkElement = try document.getElementById("openPopup") {
                    let magnetLink = try linkElement.attr("href")
                    completion(magnetLink)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing HTML: \(error)")
                completion(nil)
            }
        case let .failure(error):
            print("Error fetching URL: \(error)")
            completion(nil)
        }
    }
}

func fetchPopupButton(from url: String, completion: @escaping (String?) -> Void) {
    AF.request(url).responseString { response in
        switch response.result {
        case let .success(html):
            do {
                let document = try SwiftSoup.parse(html)
                if let button = try document.getElementById("openPopup") {
                    let buttonText = try button.text()
                    completion(buttonText)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing HTML: \(error)")
                completion(nil)
            }
        case let .failure(error):
            print("Error fetching URL: \(error)")
            completion(nil)
        }
    }
}

/*
 import Alamofire
 import Foundation
 import SwiftSoup

 let dispatchGroup = DispatchGroup()

 func fetchHTML(from url: String, completion: @escaping (Result<String, Error>) -> Void) {
     print("fetch html")
     dispatchGroup.enter() // Enter the group before starting the request
     AF.request(url).responseString { response in
         switch response.result {
         case let .success(html):
             print("success")
             completion(.success(html))
         case let .failure(error):
             print("fail")
             completion(.failure(error))
         }
         dispatchGroup.leave() // Leave the group after the request finishes
     }
 }

 func parseHTML(_ html: String) {
     do {
         let document = try SwiftSoup.parse(html)
         let elements = try document.select("a")
         for element in elements {
             let link = try element.attr("href")
             print("Link found: \(link)")
         }
     } catch {
         print("Error parsing HTML: \(error)")
     }
 }

 let url = "https://example.com"
 fetchHTML(from: url) { result in
     switch result {
     case let .success(html):
         parseHTML(html)
     case let .failure(error):
         print("Error fetching HTML: \(error)")
     }
 }

 // Wait for the dispatch group to finish, then exit the run loop
 dispatchGroup.notify(queue: .main) {
     CFRunLoopStop(CFRunLoopGetMain())
 }

 CFRunLoopRun()
 */
