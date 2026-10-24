import SwiftUI

struct ProgressViewScreen: View {
    @EnvironmentObject var store:SwayStore
    @State private var section="Overview"
    private let sections=["Overview","Activity","Achievements"]
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                Text("Progress").font(.largeTitle.bold())
                HStack(spacing:6) { ForEach(sections,id:\.self) { item in Button { section=item } label:{ SwayPill(text:item,selected:section==item) }.buttonStyle(.plain) } }
                if section == "Overview" { overview }
                else if section == "Activity" { activity }
                else { achievements }
            }.padding(18).frame(maxWidth:1000).frame(maxWidth:.infinity,alignment:.top)
        }.background(SwayTheme.background.ignoresSafeArea()).preferredColorScheme(.dark).navigationBarTitleDisplayMode(.inline)
    }
    private var overview:some View {
        VStack(alignment:.leading,spacing:18) {
            HStack(spacing:8) { stat("flame.fill","\(store.sessionsCompleted)","Workouts",.orange); stat("bolt.fill","\(dayStreak)","Day Streak",.yellow); stat("clock.fill","\(store.totalMinutes)","Minutes",SwayTheme.accent) }
            SwayCard { VStack(alignment:.leading,spacing:14) { Text("Weekly Activity").font(.headline); HStack(alignment:.bottom,spacing:12) { ForEach(0..<7,id:\.self) { n in VStack { RoundedRectangle(cornerRadius:4).fill(n==6 ? SwayTheme.accent:Color.white.opacity(0.15)).frame(height:weeklyBarHeight(n)); Text(weeklyDayLabels[n]).font(.caption2).foregroundStyle(.secondary) }.frame(maxWidth:.infinity) } }.frame(height:110,alignment:.bottom) } }
            Text("Recent Workouts").font(.headline)
            activity
        }
    }
    private var activity:some View { VStack(spacing:8) { if store.sessionResults.isEmpty { Text("Your completed workouts will appear here.").foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.leading).padding() } else { ForEach(store.sessionResults.prefix(8)) { result in HStack(spacing:12) { ZStack { RoundedRectangle(cornerRadius:12).fill(SwayTheme.stageGradient); Image(systemName:"figure.dance").foregroundStyle(SwayTheme.accent) }.frame(width:48,height:48); VStack(alignment:.leading){Text("Dance Session").bold();Text("\(result.durationMinutes) min").font(.caption).foregroundStyle(.secondary)};Spacer();Text("Completed").font(.caption.bold()).foregroundStyle(.green) }.padding(10).background(SwayTheme.surface,in:RoundedRectangle(cornerRadius:16)) } } } }
    private var achievements:some View { VStack(spacing:10) { achievement("First Steps","Complete your first workout",store.sessionsCompleted>0); achievement("Keep Moving","Complete 5 workouts",store.sessionsCompleted>=5); achievement("Move Collector","Learn 5 moves",store.learned.count>=5) } }
    private func achievement(_ title:String,_ detail:String,_ unlocked:Bool)->some View { HStack{Image(systemName:unlocked ? "star.circle.fill":"lock.circle").font(.title2).foregroundStyle(unlocked ? .yellow:.secondary);VStack(alignment:.leading){Text(title).bold();Text(detail).font(.caption).foregroundStyle(.secondary)};Spacer()}.padding().background(SwayTheme.surface,in:RoundedRectangle(cornerRadius:18)) }
    private func stat(_ icon:String,_ value:String,_ title:String,_ color:Color)->some View { VStack(spacing:6){Image(systemName:icon).foregroundStyle(color);Text(value).font(.title2.bold());Text(title).font(.caption2).foregroundStyle(.secondary)}.frame(maxWidth:.infinity).padding(.vertical,14).background(SwayTheme.surface,in:RoundedRectangle(cornerRadius:16)) }
    private var weeklyDayLabels:[String] {
        let cal=Calendar.current, today=cal.startOfDay(for:Date())
        let formatter=DateFormatter(); formatter.dateFormat="EEEEE"
        return (0..<7).map { offset in formatter.string(from:cal.date(byAdding:.day,value:offset-6,to:today)!) }
    }
    private var weeklyMinutes:[Int] {
        let cal=Calendar.current, today=cal.startOfDay(for:Date())
        return (0..<7).map { offset in
            let day=cal.date(byAdding:.day,value:offset-6,to:today)!
            return store.sessionResults.filter { cal.isDate($0.endedAt,inSameDayAs:day) }.reduce(0) { $0+$1.durationMinutes }
        }
    }
    private func weeklyBarHeight(_ index:Int)->CGFloat {
        let values=weeklyMinutes, peak=max(values.max() ?? 0,1)
        guard values.indices.contains(index), values[index] > 0 else { return 4 }
        return max(8,CGFloat(values[index])/CGFloat(peak)*88)
    }

    private var dayStreak:Int { let c=Calendar.current; let days=Set(store.sessionResults.map{c.startOfDay(for:$0.endedAt)}); guard !days.isEmpty else{return 0}; var cursor=c.startOfDay(for:Date()); if !days.contains(cursor),let y=c.date(byAdding:.day,value:-1,to:cursor),days.contains(y){cursor=y};var streak=0;while days.contains(cursor){streak += 1;guard let p=c.date(byAdding:.day,value:-1,to:cursor) else{break};cursor=p};return streak }
}
