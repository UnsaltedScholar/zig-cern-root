#include "TFile.h"
#include "TRandom3.h"
#include <Math/Boost.h>
#include <Math/Vector4D.h>
#include <ROOT/RDataFrame.hxx>
#include <cmath>
#include <iostream>
#include <vector>

struct Event {
  double px, py, pz, m;
};

int main(int argc, char **argv) {
  const unsigned long long N =
      (argc > 1) ? static_cast<unsigned long long>(std::stoull(argv[1]))
                 : 10000ULL;
  using LV = ROOT::Math::LorentzVector<ROOT::Math::PxPyPzE4D<double>>;

  // Fixed recoil vector v2
  const double px2 = 2.0, py2 = -1.0, pz2 = 1.5, m2 = 0.5;
  const double e2 = std::sqrt(px2 * px2 + py2 * py2 + pz2 * pz2 + m2 * m2);
  LV v2(px2, py2, pz2, e2);
  ROOT::Math::Boost boost_to_v2_cm(-v2.BoostToCM());

  // Generate event data in memory
  std::vector<Event> events;
  events.reserve(static_cast<std::size_t>(N));
  TRandom3 rng(0);
  for (unsigned long long i = 0; i < N; ++i) {
    Event ev;
    ev.px = rng.Gaus(0.0, 1.0);
    ev.py = rng.Gaus(0.0, 1.0);
    ev.pz = rng.Gaus(0.0, 1.0);
    ev.m = rng.Uniform(0.0, 0.3);
    events.push_back(ev);
  }

  ROOT::RDataFrame df(N);

  auto df_with_vecs =
      df.Define(
            "px",
            [&](ULong64_t i) { return events[static_cast<std::size_t>(i)].px; },
            {"rdfentry_"})
          .Define("py",
                  [&](ULong64_t i) {
                    return events[static_cast<std::size_t>(i)].py;
                  },
                  {"rdfentry_"})
          .Define("pz",
                  [&](ULong64_t i) {
                    return events[static_cast<std::size_t>(i)].pz;
                  },
                  {"rdfentry_"})
          .Define("m",
                  [&](ULong64_t i) {
                    return events[static_cast<std::size_t>(i)].m;
                  },
                  {"rdfentry_"})
          .Define("v",
                  [&](double px, double py, double pz, double m) {
                    double e = std::sqrt(px * px + py * py + pz * pz + m * m);
                    return LV(px, py, pz, e);
                  },
                  {"px", "py", "pz", "m"})
          .Define("sum", [&](const LV &v) { return v + v2; }, {"v"})
          .Define("mass", [](const LV &s) { return s.M(); }, {"sum"})
          .Define("pt", [](const LV &s) { return s.Pt(); }, {"sum"})
          .Define("rap", [](const LV &s) { return s.Rapidity(); }, {"sum"})
          .Define("deltaE",
                  [&](const LV &v) {
                    LV vb = boost_to_v2_cm(v);
                    return vb.E() - v.E();
                  },
                  {"v"});

  auto h_mass = df_with_vecs.Histo1D(
      {"h_mass", "Invariant mass;M [GeV];Entries", 100, 0.0, 10.0}, "mass");
  auto h_pt = df_with_vecs.Histo1D(
      {"h_pt", "Transverse momentum;p_{T} [GeV];Entries", 100, 0.0, 10.0},
      "pt");
  auto h_rap = df_with_vecs.Histo1D(
      {"h_rap", "Rapidity;y;Entries", 100, -5.0, 5.0}, "rap");
  auto h_deltaE = df_with_vecs.Histo1D(
      {"h_deltaE", "Energy change;ΔE [GeV];Entries", 100, -5.0, 5.0}, "deltaE");

  TFile out("analysis.root", "RECREATE");
  h_mass->Write();
  h_pt->Write();
  h_rap->Write();
  h_deltaE->Write();
  out.Close();

  std::cout << "Wrote analysis.root with " << N << " events.\n";
  std::cout << "Mass mean=" << h_mass->GetMean() << " rms=" << h_mass->GetRMS()
            << "\n";
  std::cout << "Pt mean=" << h_pt->GetMean() << " rms=" << h_pt->GetRMS()
            << "\n";
  std::cout << "Rap mean=" << h_rap->GetMean() << " rms=" << h_rap->GetRMS()
            << "\n";
  std::cout << "ΔE mean=" << h_deltaE->GetMean()
            << " rms=" << h_deltaE->GetRMS() << "\n";

  return 0;
}
