//
//  MemoryShortView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 07/03/2023.
//

import SwiftUI

struct MemoryCondensedView: View {
    
    @EnvironmentObject private var model: ViewModel
    
    // do not use the whole memory as State to avoid image flicker on rendering changes
    @State var memory : Memory
    @State var imageURL : URL? = nil// asynchronous property to retrieve the image URL
    
    var body: some View {
        VStack(alignment: .leading) {
            
            AsyncImage(url: self.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
            }
            .onAppear() {
                Task {
                    if self.imageURL == nil {
                        self.imageURL = await model.imageURL(for: memory)
                    }
                }
            }
            
            HStack {
                FavouriteView(favourite: memory.favourite)
                    .onTapGesture {
                        self.memory
                          = self.model.updateMemory(memory,
                                                    favourite: !memory.favourite,
                                                    star: memory.star)
                    }
                
                Spacer()
                
                Text(DateFormatter.localizedString(
                    from: memory.moment.toDate()!,
                    dateStyle: .none,
                    timeStyle: .short))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                StarView(number: memory.star)
                    .onTapGesture {
                        self.memory
                           = self.model.updateMemory(memory,
                                                     favourite: memory.favourite,
                                                     star: memory.star + 1)
                    }
            }
            .padding([.bottom])
        }
    }
}

struct StarView: View {
    
    var number: Int
    var body: some View {
        
        if number > 5  {
            Text("Invalid star value: \(number)")
        } else {
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { value in
                    if value <= number {
                        Image(systemName: "star.fill")
                            .renderingMode(.original)
                            .foregroundColor(.yellow)
                    } else {
                        Image(systemName: "star")
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
    }
}

struct FavouriteView: View {
    var favourite: Bool
    var body: some View {
        let icon = favourite ? "heart.fill" : "heart"
        Image(systemName: icon)
            .foregroundColor(.red)
    }
}

struct MemoryCondensedViewr_Previews: PreviewProvider {
    static var previews: some View {
        let memory = Memory.mock[Int.random(in: 0...Memory.mock.count)]
        let model = ViewModel()
        MemoryCondensedView(memory: memory).environmentObject(model)
    }
}
