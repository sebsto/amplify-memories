import SwiftUI


struct TodayView: View {
    
    @EnvironmentObject private var model: ContentView.ViewModel
    
    @Namespace var top
    
    @State public var memories: [Memory]
    @State private var offset = CGFloat.zero
    
    var body: some View {
        
        NavigationStack {
            
            ScrollViewReader { proxy in
                ScrollView {
                    
                    headerView()
                    
                    LazyVStack {
                        ForEach(Array(memories.years()), id: \.self) { year in
                            groupYear(year)
                            ForEach(memories.groupByYears()[year]!, id: \.moment) { memory in
                                
                                NavigationLink(destination: MemoryDetailView(memory: memory)) {
                                    
                                    MemoryCondensedView(memory: memory)
                                        .padding([.bottom])
                                    
                                } // NavigationLink
                            } // for each memory in a given year
                        } // for each year
                    }
                    .padding(.bottom)
                    
                    bottomView(proxy)
                    
                } // scrollview
            } // scrollviewreader
            
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .navigationSplitViewStyle(.balanced)
//            .ignoresSafeArea()
            .edgesIgnoringSafeArea([.top])
            
        } // NavigationView
    }
    
    let firstRowheight : CGFloat = 60
    
    @ViewBuilder
    func headerView() -> some View {
        // make the header view scale out when user scrolls up
        GeometryReader { geo in
            
            let geoMinY = geo.frame(in: .global).minY
            let geoMaxY = geo.frame(in: .global).maxY
            let minY = geoMinY > 0 ? geoMinY : 0
            let maxY = geoMaxY > 0 ? geoMaxY : 0
            let scaleFactor = 2 * minY / maxY
            
            Text("Today's memories")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity)
                .scaleEffect(scaleFactor)
        }
        .frame(height: firstRowheight) // to ensure teh GeometryReader view has a min Height
        .id(top)
    }
    
    @ViewBuilder
    func groupYear(_ year: Int) -> some View {
        Group {
            Text("A day like today")
                .bold()
                .foregroundColor(.gray)
            Text(String(Memory.yearsAgo(year)))
                .font(.title)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func bottomView(_ proxy: ScrollViewProxy) -> some View {
        Text("🎉That's all for today!🎉")
            .font(.title)
            .padding([.top, .bottom])
        Text("Come back tomorrow for more memories")
            .font(.headline)
            .foregroundColor(.gray)
            .padding(.bottom)
        
        Button(action: {
            withAnimation {
                proxy.scrollTo(top)
            }
        })
        {
            Image(systemName: "arrow.up")
            Text("Scroll to the top")
        }
        .padding(.bottom)
        
        Button(action: {
            self.model.signOut()
        })
        {
            Image(systemName: "rectangle.portrait.and.arrow.right")
            Text("Signout")
        }
        .padding(.bottom)
    }
}

struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        let memories = Memory.mock
        let model = ContentView.ViewModel()
        TodayView(memories: memories).environmentObject(model)
    }
}
