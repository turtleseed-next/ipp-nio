import Foundation
import IppClient

let printer = IppPrinter(
    httpClient: HTTPClient(configuration: .init(certificateVerification: .none)),
    uri: "ipps://macmini.local/printers/EPSON_XP_7100_Series"
)

let pdf = try Data(contentsOf: URL(fileURLWithPath: "Examples/PrintPDF/hi_mom.pdf"))

let response = try await printer.printJob(
    documentFormat: "application/pdf",
    data: .bytes(pdf)
)

guard response.statusCode == .successfulOk, let jobId = response[job: \.jobId] else {
    print("Print job failed with status \(response.statusCode)")
    exit(1)
}

let job = printer.job(jobId)

while true {
    let response = try await job.getJobAttributes(requestedAttributes: [.jobState])
    guard let jobState = response[job: \.jobState] else {
        print("Failed to get job state")
        exit(1)
    }

    switch jobState {
    case .aborted, .canceled, .completed:
        print("Job ended with state \(jobState)")
        exit(0)
    default:
        print("Job state is \(jobState)")
    }

    try await Task.sleep(nanoseconds: 3_000_000_000)
}
