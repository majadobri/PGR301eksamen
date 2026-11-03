package no.pgr301.exam.service;

import io.micrometer.core.instrument.DistributionSummary;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import no.pgr301.exam.model.AnalyzeResponse;
import no.pgr301.exam.model.GiftAnalysis;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
public class WishlistService {

    private final S3Service s3;
    private final RekognitionService rekognition;
    private final BedrockService bedrock;
    private final MeterRegistry meterRegistry;

    private final Timer rekognitionTimer;
    private final Timer bedrockTimer;
    private final DistributionSummary suggestionsPerAnalysis;

    public WishlistService(S3Service s3, RekognitionService rekognition, BedrockService bedrock,
                           MeterRegistry meterRegistry) {
        this.s3 = s3;
        this.rekognition = rekognition;
        this.bedrock = bedrock;
        this.meterRegistry = meterRegistry;

        // Tiden det tar å kalle Rekognition
        this.rekognitionTimer = Timer.builder("rekognition_latency")
                .description("Tid brukt på Rekognition-kallet")
                .register(meterRegistry);

        // Tiden det tar å kalle Bedrock
        this.bedrockTimer = Timer.builder("bedrock_latency")
                .description("Tid brukt på Bedrock-kallet")
                .register(meterRegistry);

        // Business: hvor mange gaveforslag hver analyse gir
        this.suggestionsPerAnalysis = DistributionSummary.builder("gift_suggestions_per_analysis")
                .description("Antall gaveforslag generert per bilde")
                .register(meterRegistry);
    }

    public AnalyzeResponse process(byte[] bytes, String filename, String contentType) {
        String s3Key = s3.upload(bytes, filename, contentType);

        List<String> labels = rekognitionTimer.record(() -> rekognition.detectLabels(bytes));
        GiftAnalysis analysis = bedrockTimer.record(() -> bedrock.suggestGifts(labels));

        // Business: antall bilder analysert
        meterRegistry.counter("images_analyzed").increment();

        int antallForslag = analysis.suggestions() == null ? 0 : analysis.suggestions().size();
        suggestionsPerAnalysis.record(antallForslag);

        return new AnalyzeResponse(
                s3Key,
                labels,
                analysis.roomAnalysis(),
                analysis.recipientProfile(),
                analysis.suggestions(),
                Instant.now().toString()
        );
    }
}
