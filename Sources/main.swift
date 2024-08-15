// The Swift Programming Language
// https://docs.swift.org/swift-book

import Alamofire
import Foundation
import SwiftSoup
import SwiftTUI

enum Status {
    case pending, loading, error
}

struct MyTerminalView: View {
    @State private var torrentLinks: [String] = []
    @State private var search: String = ""
    @State private var output: String = ""

    var body: some View {
        VStack {
            HStack {
                Text("What would you like to search for?!")
                TextField { input in
                    search = input
                    fetchHTML(from: "https://1337x.to/search/\(search)/1/") { result in
                        switch result {
                        case let .success(html):
                            torrentLinks = parseHTML(html)
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
                            openFile(at: output)
                        } else {
                            print("No torrent link found.")
                        }
                    }
                }
            }
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
    AF.request(url).responseString { response in
        switch response.result {
        case let .success(html):
            completion(.success(html))
        case let .failure(error):
            completion(.failure(error))
        }
    }
}

func parseHTML(_ html: String) -> [String] {
    do {
        let document = try SwiftSoup.parse(html)
        let links = try document.select("a[href]").compactMap { link -> String? in
            let href = try link.attr("href")
            return href.contains("/torrent/") && !href.contains("/user/") ? "https://1337x.to\(href)" : nil
        }
        return links
    } catch {
        print("Error parsing HTML: \(error)")
        return []
    }
}

func downloadTorrentFile(from link: String) -> String {
    let downloadPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Downloads/torrent_file.torrent"
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["curl", "-L", "-o", downloadPath, link]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    task.waitUntilExit()

    return downloadPath
}

func openFile(at path: String) {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["open", path]
    task.launch()
    task.waitUntilExit()
}

func fetchTorrentFileLink(from url: String, completion: @escaping (String?) -> Void) {
    AF.request(url).responseString { response in
        guard case let .success(html) = response.result else {
            completion(nil)
            return
        }
        do {
            let document = try SwiftSoup.parse(html)
            let torrentLink = try document.select("a[href$=.torrent]").first()?.attr("href")
            completion(torrentLink)
        } catch {
            print("Error parsing HTML: \(error)")
            completion(nil)
        }
    }
}
