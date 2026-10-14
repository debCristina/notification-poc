//
//  LocationManager.swift
//  Notification_POC
//
//  Created by Débora Cristina Silva Ferreira on 05/10/26.

import Foundation
import CoreLocation
import MapKit
import UserNotifications

// lógica responsável por acompanhar a localização, procurar lugares e enviar notificações.
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    // objeto responsável por gerenciar os serviços de localização do iPhone.
    private let manager = CLLocationManager()
    // Armazena uma descrição do local identificado.
    var localAtual: String = "Aguardando..."
    
    // guarda identificadores dos locais para os quais o aplicativo já enviou uma notificação durante a execução atual.
    private var ultimaVisitaNotificada: Set<String> = []
    
    override init() {
        super.init()
        // Permite que atualizações contínuas de localização ocorram em segundo plano quando o aplicativo utiliza os serviços de localização apropriados.
        manager.allowsBackgroundLocationUpdates = true
        
        // não deve pausar automaticamente as atualizações contínuas de localização por considerar que elas não são necessárias.
        manager.pausesLocationUpdatesAutomatically = false
        
        // informa ao CLLocationManager que o próprio objeto LocationManager receberá os eventos de localização.
        manager.delegate = self
    }
    
    //  função é responsável por iniciar o processo de configuração do rastreamento
    func startTracking() {
        
        // Solicita ao usuário a autorização para acessar a localização em situações que incluem o uso em segundo plano.
        manager.requestAlwaysAuthorization()
        // solicita autorização para exibir notificações.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in }
        //solicita ao iOS que monitore visitas a locais.
        print("Monitoramento de visitas disponível: \(CLLocationManager.isMonitoringAvailable(for: CLVisit.self))")
        manager.startMonitoringVisits()
        print("Monitoramento de visitas solicitado")
        manager.startUpdatingLocation()
        
        print("comecou")
       
    }
    
    //  chamada pelo sistema quando o CLLocationManager recebe atualizações de localização.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // array de objetos CLLocation.
        guard let coordinate = locations.last?.coordinate else { return }
        
        Task {
            // função buscarCategoria realiza uma pesquisa de lugares usando o MapKit.
            let item = await buscarCategoria(em: coordinate)
            
            await MainActor.run {
                guard let item else { return }
                // Se item.name tiver um valor, utiliza esse valor.
                // Se item.name for nil, utiliza "desconhecido".
                let nome = item.name ?? "desconhecido"
                
                let categoria = item.pointOfInterestCategory?.rawValue
                    .replacingOccurrences(of: "MKPOICategory", with: "") ?? "desconhecido"
                // atualizar o local atual
                self.localAtual = "\(categoria) — \(nome)"
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        // verificar se o usuário chegou ao local
        
        print("DID VISIT FOI CHAMADO!")
        
        print("Latitude: \(visit.coordinate.latitude)")
        
        print("Longitude: \(visit.coordinate.longitude)")
        
        print("Chegada: \(visit.arrivalDate)")
        
        print("Saída: \(visit.departureDate)")
        
        
        guard visit.departureDate == .distantFuture else {
            print("Visita ignorada: a visita não está em andamento")
            return
        }
        Task {
            // pesquisar o lugar visitado
            let item = await buscarCategoria(em: visit.coordinate)
            await MainActor.run {
                //  verificar se o lugar e o nome existem
                guard let item, let nome = item.name else { return }
                
                //  criar uma identificação para o local
                let chave = "\(nome)-\(Int(visit.coordinate.latitude * 1000))"
                
                // verificar se a notificação já foi enviada
                guard !ultimaVisitaNotificada.contains(chave) else { return }
                
                // registrar a notificação
                ultimaVisitaNotificada.insert(chave)
                
                // atualiza a propriedade observável com o nome e a categoria do lugar visitado.
                let categoria = item.pointOfInterestCategory?.rawValue
                    .replacingOccurrences(of: "MKPOICategory", with: "") ?? "desconhecido"
                self.localAtual = "\(categoria) — \(nome)"
                // chama enviarNotificacao, que cria e agenda a notificação local.
                enviarNotificacao(titulo: "Você chegou!", corpo: "Você está em \(nome) — \(categoria)")
            }
        }
    }
    
    
    private func enviarNotificacao(titulo: String, corpo: String) {
        let content = UNMutableNotificationContent()
        content.title = titulo
        content.body = corpo
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func buscarCategoria(em coordinate: CLLocationCoordinate2D) async -> MKMapItem? {
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: 50)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .beach, .park, .nationalPark, .fitnessCenter, .foodMarket, .pharmacy, .museum, .library, .university, .school, .publicTransport, .school])
        
        do {
            let response = try await MKLocalSearch(request: request).start()
            
            print("Quantidade de lugares encontrados: \(response.mapItems.count)")
            
            for item in response.mapItems {
                print("Nome: \(item.name ?? "Sem nome")")
                print("Categoria: \(String(describing: item.pointOfInterestCategory))")
                print("----------------------")
            }
            
            return response.mapItems.first
            
        } catch {
            print("Erro na pesquisa: \(error.localizedDescription)")
            return nil
        }
    }
   
}

