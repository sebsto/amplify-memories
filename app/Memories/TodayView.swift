import SwiftUI


struct TodayView: View {
    
    @EnvironmentObject private var model: ViewModel
    
    @Namespace var top
    
    @State private var offset = CGFloat.zero
    
    var body: some View {
        
        let memories = model.memories
        
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
//            .ignoresSafeArea(edges: [.top])
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
            let scaleFactor = (2 * minY / maxY) 
//            let scaleFactor : CGFloat = geoMinY >= 0 ? 1 : 0
            
            Text("Today's memories")
//            Text("\(geoMinY) x \(geoMaxY)")
                .font(.largeTitle)
                .bold()
//                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
//                .position(x:geo.frame(in: .global).midX, y:geo.frame(in: .global).midY + 10)
                .scaleEffect(scaleFactor)
        }
        .frame(height: firstRowheight) // to ensure teh GeometryReader view has a min Height
//        .background(.tint)

        .id(top)
    }
    
    @ViewBuilder
    func groupYear(_ year: Int) -> some View {
        Group {
            let yearsAgo = Memory.yearsAgo(year)
            if yearsAgo != "Today" {
                Text("A day like today")
                    .bold()
                    .foregroundColor(.gray)
            }
            Text(String(yearsAgo))
                .font(.title)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func bottomView(_ proxy: ScrollViewProxy) -> some View {
        if self.model.memories.count > 0 {
            Text("🎉That's all for today!🎉")
                .font(.title)
                .padding([.top, .bottom])
        } else {
            Text("No recorded memory for today")
                .font(.title3)
                .padding([.top, .bottom])
        }
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
        let model = ViewModel(memories: Memory.mock)
//        let model = ViewModel(memories: [])
        TodayView().environmentObject(model)
    }
}
