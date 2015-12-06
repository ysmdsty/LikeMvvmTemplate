import UIKit
import Bond
import SwiftyJSON

class SwiftBondDemoSecondViewController: UITableViewController {
    var listViewModel: ListViewModel = ListViewModel()
    var dataSource: ObservableArray<ObservableArray<ListCellViewModel>>! // Sections<Rows<ListCellViewModel>>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        self.tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: Selector("loadNextSet:"), forControlEvents: UIControlEvents.ValueChanged)
        
        dataSource = ObservableArray([listViewModel.repositoryCellViewModels])
        dataSource.bindTo(tableView) { (indexPath, dataSource, tableView) -> UITableViewCell in
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! SwiftBondDemoSecondCell
            let viewModel = dataSource[indexPath.section][indexPath.row]
            viewModel.name.bindTo(cell.nameLabel.bnd_text).disposeIn(cell.bnd_bag)
            viewModel.photo.bindTo(cell.avatarImageView.bnd_image).disposeIn(cell.bnd_bag)
            viewModel.fetchPhotoIfNeeded()
            return cell
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        listViewModel.fetchNextPageOfRepositories() {}
    }
    func loadNextSet(refreshControl: UIRefreshControl) {
        listViewModel.fetchNextPageOfRepositories() {refreshControl.endRefreshing()}
    }
}

class SwiftBondDemoSecondCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        bnd_bag.dispose()
    }
}

class ListViewModel {
    let repositoryCellViewModels: ObservableArray<ListCellViewModel> = ObservableArray([])
    private var apiURL: NSURL! {return NSURL(string: "https://api.github.com/repositories" + "?since=\(since)")}
    private var since = 0
    
    func fetchNextPageOfRepositories(completion: () -> Void) {
        Mock.dispatchAsyncGlobal {
            guard let data = NSData(contentsOfURL: self.apiURL) else {return}
            guard let jsonResult = JSON(data: data, options: .MutableLeaves, error: nil).array else {return}
            Mock.dispatchAsyncMain({
                var newRepos: [ListCellViewModel] = []
                for repo in jsonResult {
                    let id = repo["id"].intValue
                    let name = repo["name"].stringValue
                    let owner = repo["owner"].dictionary
                    let username = owner?["login"]?.stringValue ?? ""
                    let photoURL = owner?["avatar_url"]?.stringValue
                    self.since = max(self.since, id)
                    newRepos.append(ListCellViewModel(name: name, username: username, photoUrl: photoURL))
                }
                self.repositoryCellViewModels.insertContentsOf(newRepos.reverse(), atIndex: 0)
                completion()
            })
        }
    }
}

class ListCellViewModel {
    let name: Observable<String>
    let photo: Observable<UIImage?>
    let photoUrl: String?
    
    init(name: String, username: String, photoUrl: String?) {
        self.name = Observable(name)
        self.photo = Observable<UIImage?>(nil) // initially no photo
        self.photoUrl = photoUrl
    }
    
    func fetchPhotoIfNeeded() {
        if self.photo.value != nil {return}
        guard let photoUrlStr = photoUrl else {return}
        guard let photoUrl = NSURL(string: photoUrlStr) else {return}
        
        NSURLSession.sharedSession()
            .downloadTaskWithURL(photoUrl) { [weak self] location, response, error in
                guard let location = location, data = NSData(contentsOfURL: location), image = UIImage(data: data) else {return}
                Mock.dispatchAsyncMain { self?.photo.value = image }
            }.resume()
    }
}
