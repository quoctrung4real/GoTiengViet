import Foundation

/// Vietnamese word dictionary for autocomplete suggestions
/// Uses a prefix trie for fast lookups
class WordDictionary {

    /// Shared singleton
    static let shared = WordDictionary()

    /// Trie node
    private class TrieNode {
        var children: [Character: TrieNode] = [:]
        var isWord: Bool = false
        var frequency: Int = 0  // Higher = more common
    }

    /// Root of the trie
    private let root = TrieNode()

    /// Maximum suggestions to return
    private let maxSuggestions = 8

    /// Number of words loaded
    private(set) var wordCount: Int = 0

    // MARK: - Initialization

    private init() {
        loadBuiltInDictionary()
    }

    // MARK: - Loading

    /// Load the built-in Vietnamese word list
    private func loadBuiltInDictionary() {
        // Common Vietnamese words with frequencies (higher = more common)
        // This is a curated list of ~500 most common words
        let commonWords: [(String, Int)] = [
            // Top frequency words
            ("không", 100), ("có", 99), ("là", 98), ("của", 97), ("được", 96),
            ("trong", 95), ("cho", 94), ("và", 93), ("những", 92), ("với", 91),
            ("các", 90), ("này", 89), ("một", 88), ("người", 87), ("đã", 86),
            ("như", 85), ("từ", 84), ("đến", 83), ("nhưng", 82), ("khi", 81),
            ("về", 80), ("cũng", 79), ("phải", 78), ("sẽ", 77), ("còn", 76),
            ("năm", 75), ("tôi", 74), ("trên", 73), ("nhiều", 72), ("thì", 71),
            ("theo", 70), ("ra", 69), ("đó", 68), ("nếu", 67), ("rất", 66),
            ("tại", 65), ("vì", 64), ("do", 63), ("hay", 62), ("hoặc", 61),
            ("đang", 60), ("nào", 59), ("vào", 58), ("bị", 57), ("nên", 56),
            ("lại", 55), ("sau", 54), ("mà", 53), ("trước", 52), ("thế", 51),
            // High frequency
            ("anh", 50), ("chị", 49), ("em", 48), ("ông", 47), ("bà", 46),
            ("nhà", 45), ("nước", 44), ("công", 43), ("việc", 42), ("làm", 41),
            ("đi", 40), ("biết", 39), ("muốn", 38), ("thời", 37), ("gian", 36),
            ("ngày", 35), ("đây", 34), ("mới", 33), ("lên", 32), ("xuống", 31),
            ("bạn", 30), ("chúng", 29), ("tôi", 28), ("hơn", 27), ("giữa", 26),
            ("cần", 25), ("chỉ", 24), ("hiện", 23), ("đầu", 22), ("cuối", 21),
            // Medium frequency
            ("phát", 20), ("triển", 19), ("kinh", 18), ("tế", 17), ("chính", 16),
            ("trị", 15), ("xã", 14), ("hội", 13), ("giáo", 12), ("dục", 11),
            ("quốc", 10), ("gia", 9), ("thành", 8), ("phố", 7), ("tỉnh", 6),
            ("huyện", 5), ("thôn", 4), ("xóm", 3), ("phường", 2), ("quận", 1),
            // Compound words / common phrases (2-syllable)
            ("Việt Nam", 85), ("thành phố", 70), ("chính phủ", 65),
            ("kinh tế", 60), ("giáo dục", 55), ("xã hội", 50),
            ("phát triển", 45), ("thời gian", 40), ("công nghệ", 35),
            ("văn hóa", 30), ("sức khỏe", 25), ("trường học", 20),
            ("bệnh viện", 15), ("tổ chức", 10), ("nghiên cứu", 8),
            // Technology terms
            ("máy tính", 40), ("phần mềm", 35), ("internet", 30),
            ("điện thoại", 28), ("ứng dụng", 25), ("dữ liệu", 20),
            ("trí tuệ", 15), ("nhân tạo", 12), ("thông tin", 10),
            // Common verbs
            ("đọc", 45), ("viết", 44), ("nghe", 43), ("nói", 42), ("xem", 41),
            ("ăn", 40), ("uống", 39), ("ngủ", 38), ("chạy", 37), ("đứng", 36),
            ("ngồi", 35), ("mở", 34), ("đóng", 33), ("bắt đầu", 32), ("kết thúc", 31),
            ("hiểu", 30), ("nhớ", 29), ("quên", 28), ("thích", 27), ("yêu", 26),
            ("ghét", 25), ("sợ", 24), ("tin", 23), ("nghĩ", 22), ("cảm thấy", 21),
            // Common adjectives
            ("tốt", 50), ("xấu", 49), ("đẹp", 48), ("lớn", 47), ("nhỏ", 46),
            ("cao", 45), ("thấp", 44), ("nhanh", 43), ("chậm", 42), ("mạnh", 41),
            ("yếu", 40), ("dài", 39), ("ngắn", 38), ("rộng", 37), ("hẹp", 36),
            ("nóng", 35), ("lạnh", 34), ("sáng", 33), ("tối", 32), ("trắng", 31),
            ("đen", 30), ("đỏ", 29), ("xanh", 28), ("vàng", 27), ("tím", 26),
            // Common nouns
            ("người", 50), ("nhà", 49), ("nước", 48), ("đất", 47), ("trời", 46),
            ("mưa", 45), ("nắng", 44), ("gió", 43), ("biển", 42), ("sông", 41),
            ("núi", 40), ("rừng", 39), ("cây", 38), ("hoa", 37), ("con", 36),
            ("mắt", 35), ("tay", 34), ("chân", 33), ("đầu", 32), ("lòng", 31),
            // Time words
            ("hôm nay", 50), ("ngày mai", 48), ("hôm qua", 46),
            ("tuần", 44), ("tháng", 42), ("năm", 40),
            ("sáng", 38), ("trưa", 36), ("chiều", 34), ("tối", 32),
            // Greetings & common phrases
            ("xin chào", 60), ("cảm ơn", 55), ("xin lỗi", 50),
            ("tạm biệt", 45), ("chúc mừng", 40),
        ]

        for (word, freq) in commonWords {
            insert(word: word.lowercased(), frequency: freq)
        }

        wordCount = commonWords.count
        Log.engine("Loaded \(wordCount) words into dictionary")
    }

    // MARK: - Trie Operations

    /// Insert a word into the trie
    func insert(word: String, frequency: Int = 1) {
        var node = root
        for char in word {
            if node.children[char] == nil {
                node.children[char] = TrieNode()
            }
            node = node.children[char]!
        }
        node.isWord = true
        node.frequency = max(node.frequency, frequency)
    }

    /// Get autocomplete suggestions for a prefix
    /// - Parameter prefix: The typed prefix
    /// - Returns: Array of (word, frequency) tuples sorted by frequency descending
    func suggest(prefix: String) -> [(String, Int)] {
        let lower = prefix.lowercased()
        guard !lower.isEmpty else { return [] }

        // Navigate to the prefix node
        var node = root
        for char in lower {
            guard let next = node.children[char] else {
                return []  // Prefix not found
            }
            node = next
        }

        // Collect all words from this node
        var results: [(String, Int)] = []
        collectWords(node: node, prefix: lower, results: &results)

        // Sort by frequency (descending) and limit
        return results
            .sorted { $0.1 > $1.1 }
            .prefix(maxSuggestions)
            .map { ($0.0, $0.1) }
    }

    /// Recursively collect words from a trie node
    private func collectWords(node: TrieNode, prefix: String, results: inout [(String, Int)]) {
        if node.isWord {
            results.append((prefix, node.frequency))
        }

        // Limit depth to prevent infinite traversal
        guard results.count < maxSuggestions * 3 else { return }

        for (char, child) in node.children.sorted(by: { $0.key < $1.key }) {
            collectWords(node: child, prefix: prefix + String(char), results: &results)
        }
    }

    /// Learn a new word (add to dictionary from user typing)
    func learnWord(_ word: String) {
        let lower = word.lowercased()
        guard lower.count >= 2 else { return }  // Don't learn single characters

        // Check if already exists
        var node = root
        for char in lower {
            guard let next = node.children[char] else {
                // New word — insert with low frequency
                insert(word: lower, frequency: 1)
                wordCount += 1
                return
            }
            node = next
        }

        // Already exists — boost frequency
        if node.isWord {
            node.frequency += 1
        } else {
            node.isWord = true
            node.frequency = 1
            wordCount += 1
        }
    }
}
