import Foundation
import XCTest
import ReactiveCocoa
import Result
import KsApi
import Prelude
@testable import KsApi
@testable import Library
@testable import ReactiveExtensions_TestHelpers

internal final class ProfileViewModelTests: TestCase {
  let vm = ProfileViewModel()
  let user = TestObserver<User, NoError>()
  let hasBackedProjects = TestObserver<Bool, NoError>()
  let goToProject = TestObserver<Project, NoError>()
  let goToRefTag = TestObserver<RefTag, NoError>()
  let goToSettings = TestObserver<Void, NoError>()
  let showEmptyState = TestObserver<Bool, NoError>()

  internal override func setUp() {
    super.setUp()
    self.vm.outputs.user.observe(user.observer)
    self.vm.outputs.backedProjects.map { !$0.isEmpty }.observe(hasBackedProjects.observer)
    self.vm.outputs.goToProject.map { $0.0 }.observe(goToProject.observer)
    self.vm.outputs.goToProject.map { $0.1 }.observe(goToRefTag.observer)
    self.vm.outputs.goToSettings.observe(goToSettings.observer)
    self.vm.outputs.showEmptyState.observe(showEmptyState.observer)
  }

  func testGoToSettings() {
    self.vm.inputs.settingsButtonTapped()
    self.goToSettings.assertValueCount(1, "Go to settings screen.")
  }

  func testProjectCellTapped() {
    let project = Project.template
    self.vm.inputs.projectTapped(project)

    self.goToProject.assertValues([project], "Project emmitted.")
    self.goToRefTag.assertValues([.profileBacked], "RefTag =profile_backed emitted.")
  }

  func testUserWithBackedProjectsWithProfileViewTracking() {
    let currentUser = User.template

    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: currentUser))
    self.vm.inputs.viewWillAppear(false)
    self.scheduler.advance()

    self.user.assertValues([currentUser, currentUser], "Current user immediately emmitted and refreshed.")
    self.hasBackedProjects.assertValues([true])
    self.showEmptyState.assertValues([false])

    XCTAssertEqual(["Profile View My", "Viewed Profile"], trackingClient.events)
  }

  func testUserWithBackedProjectsWithoutProfileViewTracking() {
    let currentUser = User.template

    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: currentUser))
    self.vm.inputs.viewWillAppear(true)
    self.scheduler.advance()

    self.user.assertValues([currentUser, currentUser], "Current user immediately emmitted and refreshed.")
    self.hasBackedProjects.assertValues([true])
    self.showEmptyState.assertValues([false])

    XCTAssertEqual([], trackingClient.events)
  }

  func testUserWithNoProjectsWithViewWillAppearAnimatedFalse() {
    let response = .template |> DiscoveryEnvelope.lens.projects .~ []

    withEnvironment(apiService: MockService(fetchDiscoveryResponse: response)) {
      AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: .template))

      self.vm.inputs.viewWillAppear(false)

      self.scheduler.advance()

      self.hasBackedProjects.assertValues([false])
      self.showEmptyState.assertValues([true], "Empty state is shown for user with 0 backed projects.")
    }
  }

  func testUserWithNoProjectsWithViewWillAppearAnimatedTrue() {
    let response = .template |> DiscoveryEnvelope.lens.projects .~ []

    withEnvironment(apiService: MockService(fetchDiscoveryResponse: response)) {
      AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: .template))

      self.vm.inputs.viewWillAppear(true)

      self.scheduler.advance()

      self.hasBackedProjects.assertValues([false])
      self.showEmptyState.assertValues([true], "Empty state is shown for user with 0 backed projects.")
    }
  }
}
