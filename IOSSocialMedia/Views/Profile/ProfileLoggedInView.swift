import SwiftUI

struct ProfileLoggedInView: View {
    @State private var isDarkMode = false
    var body: some View{
        // nen chinh
        ZStack{
            // doi mau tu dong
            Color(.systemBackground).ignoresSafeArea()
            
            //xep thanh hang ngang
            VStack(spacing : 0 ){
                HeaderView(isDarkMode:$isDarkMode)
                ScrollView{
                    VStack(alignment: .leading,spacing: 10                                   ){
                        ProfileHeaderView()
                        BioView()
                        FollowedByView()
                        ActionButtonsView()
                        HighlightView()
                        TabsView()
                        PhotoGridsView()
                    }.padding(20) // Padding dưới cùng để không bị che bởi tab bar
                        
                 
                }
            }
        }.navigationTitle("") // Đặt title rỗng
            .navigationBarHidden(true) // Ẩn luôn thanh bar hệ thống
            .navigationBarBackButtonHidden(true) // Ẩn nút back mặc định nếu có
            .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
// MARK: - 1. HEADER
struct HeaderView:View{
    @Binding var isDarkMode :Bool
    var body: some View{
        HStack{
            Image(systemName:"arrow.left").font(.title2)
            
            Spacer()
            
            //Nut Chuyen giao dien (Mặt trăng/ Mặt trời)
            Button(action: {isDarkMode.toggle()}){
                Image(systemName: isDarkMode ? "moon.fill":"sun.max.fill").font(.title2).foregroundColor(.primary)
             	
            }
            Image(systemName:"ellipsis").font(.title2).padding(.leading,15)
        }.padding()
            .foregroundColor(.primary)
            .background(Color(UIColor.systemBackground))
    }
}

// MARK: - 2. PROFILE INFO (Avatar + Số liệu)
struct ProfileHeaderView :View {
    var body: some View {
        HStack(alignment:.center,spacing: 20){
            //avatar
            Image(systemName:"cat.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 85,height: 85)
                .clipShape(Circle())
                .foregroundColor(.primary)
                .overlay(Circle().stroke(Color.gray,lineWidth: 0.5))
            
            Spacer()
            
            //Stats
            HStack(spacing:20){
                StatView(number:"970",label:"bài viết")
                StatView(number: "158K", label: "người theo dõi")
                StatView(number: "0", label: "đang theo dõi")
            }
            Spacer()
        }.padding(.horizontal)
        
    
    }
}

// Component con hiển thị số (Reusable Component)
struct StatView:View {
    let number : String
    let label : String
    var body: some View {
        VStack(spacing:2){
            Text(number)
                .font(.headline)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - 3. BIO (Tiểu sử)
struct BioView:View {
    var body: some View {
        VStack(alignment:.leading,spacing: 5){
            Text("Ai Mà biết được")
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(.primary)
            Text("Trang giai tri")
                .foregroundColor(.gray)
            
            Group{
                Text("The Vietnamese Culture on Instagram 🇻🇳")
                Text("Welcome to the culture 🙌")
            }.foregroundColor(.primary)
            
            Text("Xem ban dich")
                .font(.caption)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(.primary)
            HStack(spacing:5){
                Image(systemName:"link")
                    .font(.caption)
                    .foregroundColor(.primary)
                Text("Shoppe.vn")
                    .foregroundColor(Color(UIColor.systemBlue))
            }
            
            //threads bage
            HStack{
                Image(systemName:"at")
                    .font(.caption)
                Text("dong.vn")
                    .font(.caption)
            }
            .padding(6)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(Capsule())
            .foregroundColor(.primary)
            
        }
        .padding(.horizontal)
        .font(.subheadline)
    }
}


// MARK: - 4. FOLLOWED BY
struct FollowedByView:View {
    var body: some View {
        HStack{
            // avatar chong len nhau
            ZStack{
                Circle().fill(Color.gray).frame(width:20)
                Circle().fill(Color(UIColor.systemBackground)).frame(width:20).offset(x:14)
                Circle().fill(Color.blue).frame(width:20).offset(x:28)
            }
            .frame(width: 50,height: 20,alignment: .leading)
            Text("Có **wife_meoz**, **npdand** và **namcito** theo dõi")
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
            
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - 5. ACTION BUTTONS
struct ActionButtonsView : View {
    @State private var isFollowing = false
    var body: some View {
        HStack(spacing : 8){
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)){
                    isFollowing.toggle()
                }
                
            }) {
                Text(isFollowing ? "Đang theo dõi":"Theo dõi" )
                    .font(.footnote)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical ,8)
                // Nếu đang theo dõi: Màu nền xám nhạt. Nếu chưa: Màu xanh
                    .background(isFollowing ? Color(UIColor.secondarySystemBackground) : Color.blue)
                                    // Nếu đang theo dõi: Chữ đen/trắng (theo theme). Nếu chưa: Chữ trắng
                    .foregroundColor(isFollowing ? .primary : .white)
                    .cornerRadius(8)
            }
            Button(action: {}) {
                            Text("Nhắn tin")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color(UIColor.secondarySystemBackground)) // Xám nhạt
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
            
        }
    }
}

// MARK: - 6. HIGHLIGHTS
struct HighlightView:View {
    let items = ["Link Áo 🕺", "Feedback🎯", "📦", "Q&A"]
    var body: some View {
        ScrollView(.horizontal,showsIndicators: false){
            HStack(spacing: 15){
                ForEach(items,id: \.self) { item in
                    VStack{
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(width: 60,height: 60)
                            .overlay(
                                Circle().stroke(Color(uiColor: .separator),lineWidth: 1)
                            )
                            .overlay(Image(systemName: "Photo")
                                .foregroundColor(.primary))
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - 7. TABS
struct TabsView:View {
    var body: some View {
        HStack(spacing : 0){
            VStack{
                Image(systemName:"square.grid.3x3")
                    .font(.title3)
                Rectangle().frame(height: 1).foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
//            VStack{
//                Image(systemName: "play.rectangle")
//                    .font(.title3)
//                    .foregroundColor(.gray)
//                Rectangle().frame(height: 1).foregroundColor(.clear)
//            }
//            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
//            VStack{
//                Image(systemName: "person.crop.square")
//                    .font(.title3)
//                    .foregroundColor(.gray)
//                Rectangle().frame(height: 1).foregroundColor(.clear)
//            }
//            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
        }
    }
}

// MARK: - 8. PHOTO GRID (Yêu cầu iOS 14+)
struct PhotoGridsView:View {
    // Grid 3 cột, khoảng cách 1px
    let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    var body: some View {
        LazyVGrid(columns : columns, spacing : 1){
            ForEach(0..<15,id :\.self){ _ in
            Rectangle()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .aspectRatio(1 ,contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                    .overlay(
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .padding(5),
                    alignment: .topTrailing
                    )
                    .clipped()
            }
        }
    }
}



struct ProfileLoggedInView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileLoggedInView()
    }
}
