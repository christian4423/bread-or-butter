//
//  FuelBar.swift
//  burnzone-ui Watch App
//
//  The fat/carb ratio drawn as one fused object: a stick of butter on the
//  left and a French baguette on the right, split by a sliding divider that
//  sits exactly at the fat-vs-carb boundary. Both icons are drawn full-width
//  and masked at the seam so they keep their natural shape as the ratio moves.
//

import SwiftUI

private extension Color {
    static let butterFill = Color(red: 0.961, green: 0.851, blue: 0.502)
    static let butterStroke = Color(red: 0.875, green: 0.655, blue: 0.157)
    static let butterHighlight = Color(red: 0.984, green: 0.937, blue: 0.737)
    static let breadFill = Color(red: 0.953, green: 0.745, blue: 0.475)
    static let breadStroke = Color(red: 0.855, green: 0.518, blue: 0.125)
    static let breadScore = Color(red: 0.769, green: 0.439, blue: 0.102)
}

/// A stick of butter drawn to fill its bounds.
private struct ButterIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = h * 0.08

            let stick = CGRect(x: w * 0.02, y: h * 0.24, width: w * 0.96, height: h * 0.52)
            let stickPath = Path(roundedRect: stick, cornerRadius: h * 0.11)
            ctx.fill(stickPath, with: .color(.butterFill))
            ctx.stroke(stickPath, with: .color(.butterStroke), lineWidth: lw)

            // Soft top highlight to give the pat a little dimension.
            let hi = Path(roundedRect: CGRect(x: w * 0.05, y: h * 0.31, width: w * 0.90, height: h * 0.15),
                          cornerRadius: h * 0.075)
            ctx.fill(hi, with: .color(.butterHighlight))

            // Segment ticks along the top, like a wrapped stick of butter.
            for fx in stride(from: 0.12, through: 0.88, by: 0.12) {
                var tick = Path()
                tick.move(to: CGPoint(x: w * fx, y: h * 0.30))
                tick.addLine(to: CGPoint(x: w * fx, y: h * 0.44))
                ctx.stroke(tick, with: .color(.butterStroke), lineWidth: h * 0.045)
            }
        }
    }
}

/// A French baguette, pointed on the right, drawn to fill its bounds.
private struct BaguetteIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = h * 0.08

            let loaf = CGRect(x: w * 0.01, y: h * 0.22, width: w * 0.98, height: h * 0.56)
            let body = Path(roundedRect: loaf, cornerRadius: h * 0.28)
            ctx.fill(body, with: .color(.breadFill))
            ctx.stroke(body, with: .color(.breadStroke),
                       style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Diagonal crust scores across the loaf.
            for sx in stride(from: 0.40, through: 0.82, by: 0.14) {
                var slash = Path()
                slash.move(to: CGPoint(x: w * sx, y: h * 0.54))
                slash.addLine(to: CGPoint(x: w * (sx + 0.05), y: h * 0.30))
                ctx.stroke(slash, with: .color(.breadScore),
                           style: StrokeStyle(lineWidth: h * 0.06, lineCap: .round))
            }
        }
    }
}

/// The complete ratio bar. `fatFraction` (0...1) sets where the divider sits.
struct FuelRatioBar: View {
    var fatFraction: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let seam = w * min(max(fatFraction, 0), 1)

            ZStack(alignment: .leading) {
                ButterIcon()
                    .mask(alignment: .leading) { Rectangle().frame(width: seam) }

                BaguetteIcon()
                    .mask(alignment: .trailing) { Rectangle().frame(width: max(0, w - seam)) }

                // The sliding divider — a little butter knife between the two.
                Capsule()
                    .fill(Color(white: 0.96))
                    .frame(width: max(6, w * 0.035), height: h * 0.94)
                    .position(x: seam, y: h / 2)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FuelRatioBar(fatFraction: 0.85).frame(height: 60)
        FuelRatioBar(fatFraction: 0.5).frame(height: 60)
        FuelRatioBar(fatFraction: 0.15).frame(height: 60)
    }
    .padding()
}
