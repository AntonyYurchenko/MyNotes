import UIKit

class NoteTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setNote(_ note: Note) {
        for title in note.title.components(separatedBy: "\n") {
            if !title.isEmpty {
                titleLabel.text = title
            }
        }
        
        for text in note.text.components(separatedBy: "\n") {
            if !text.isEmpty {
                noteLabel.text = text
                break
            } else {
                noteLabel.text = "No additional text"
            }
        }
        
        dateLabel.text = note.date
    }
}
