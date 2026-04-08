import Foundation

class RSSParserService: NSObject, XMLParserDelegate {
    private var articles: [Article] = []
    private var sourceName: String = ""
    
    // Parser State
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentImageURL: String? = nil
    
    private let isoFormatter = ISO8601DateFormatter()
    private let rfc822Formatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        // Standard RSS pubDate formats
        df.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return df
    }()
    
    func parse(xmlData: Data, source: String) -> [Article] {
        self.articles = []
        self.sourceName = source
        
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()
        
        return articles
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if currentElement == "item" || currentElement == "entry" {
            // Reset for new item
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
            currentImageURL = nil
        }
        
        // Extract images from enclosure tags or Atom links
        if elementName == "enclosure", let url = attributeDict["url"] {
            currentImageURL = url
        } else if elementName == "link", let rel = attributeDict["rel"], rel == "enclosure", let href = attributeDict["href"] {
            currentImageURL = href
        } else if elementName == "media:content", let url = attributeDict["url"] {
            currentImageURL = url
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !data.isEmpty else { return }
        
        switch currentElement {
        case "title": currentTitle += data
        case "link": currentLink += data
        case "description", "summary": currentDescription += data
        case "pubDate", "updated", "dc:date": currentPubDate += data
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            // Normalize Date
            let isoDate = normalizeDate(currentPubDate)
            
            let article = Article(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                url: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                image_url: currentImageURL,
                publishedAt: isoDate,
                newsSite: sourceName
            )
            articles.append(article)
        }
    }
    
    private func normalizeDate(_ dateString: String) -> String {
        // Attempt RSS format (RFC 822) 
        if let date = rfc822Formatter.date(from: dateString) {
            return isoFormatter.string(from: date)
        }
        
        // Attempt Atom default (ISO 8601)
        if let date = isoFormatter.date(from: dateString) {
            return isoFormatter.string(from: date)
        }
        
        // Return original if parsing fails (fallback to raw string)
        return dateString
    }
}
