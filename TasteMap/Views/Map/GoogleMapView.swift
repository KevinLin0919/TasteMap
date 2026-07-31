import CoreLocation
import GoogleMaps
import SwiftUI

/// Google 底圖。
///
/// 用 Google 而非 MapKit 是條款 §5.3 的必然結果 —— Places 資料不得與非 Google
/// 地圖並用（見 ADR 0001）。附帶的好處是底圖本身就有 Google 的 POI：第一天打開
/// app、還沒記過任何東西時，地圖上依然滿是店家可以探索，空的只是你自己的圖釘。
struct GoogleMapView: UIViewRepresentable {
    let places: [Place]
    let onSelectPlace: (Place) -> Void
    /// 點擊底圖上尚未記錄的 Google POI。回傳 place_id、名稱與座標，
    /// 剛好是建立一個 Place 所需要的全部資料。
    let onSelectPOI: (String, String, CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition(latitude: 25.044, longitude: 121.545, zoom: 13)

        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.sync(places, on: mapView)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        /// 只在成員變動時重畫。每次 SwiftUI 更新都清空重加會讓地圖閃爍。
        private var markers: [UUID: GMSMarker] = [:]

        init(_ parent: GoogleMapView) {
            self.parent = parent
        }

        func sync(_ places: [Place], on mapView: GMSMapView) {
            let wanted = Set(places.map(\.id))

            for (id, marker) in markers where !wanted.contains(id) {
                marker.map = nil
                markers.removeValue(forKey: id)
            }

            for place in places {
                let marker = markers[place.id] ?? GMSMarker()
                marker.position = CLLocationCoordinate2D(
                    latitude: place.latitude,
                    longitude: place.longitude
                )
                marker.title = place.name
                marker.snippet = "\(place.currentScore.formatted(.number.precision(.fractionLength(1)))) / 5 · 去過 \(place.visits.count) 次"
                marker.icon = GMSMarker.markerImage(
                    with: place.currentScore >= 4.5 ? UIColor(TasteTheme.gold) : UIColor(TasteTheme.moss)
                )
                marker.userData = place.id
                marker.map = mapView
                markers[place.id] = marker
            }
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            guard let id = marker.userData as? UUID,
                  let place = parent.places.first(where: { $0.id == id })
            else { return false }

            parent.onSelectPlace(place)
            return true
        }

        func mapView(
            _ mapView: GMSMapView,
            didTapPOIWithPlaceID placeID: String,
            name: String,
            location: CLLocationCoordinate2D
        ) {
            parent.onSelectPOI(placeID, name, location)
        }
    }
}
