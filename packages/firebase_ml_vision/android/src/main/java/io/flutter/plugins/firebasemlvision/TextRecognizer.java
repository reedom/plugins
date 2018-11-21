package io.flutter.plugins.firebasemlvision;

import android.graphics.Point;
import android.graphics.Rect;
import android.support.annotation.NonNull;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.text.FirebaseVisionCloudTextRecognizerOptions;
import com.google.firebase.ml.vision.text.FirebaseVisionText;
import com.google.firebase.ml.vision.text.FirebaseVisionTextRecognizer;
import com.google.firebase.ml.vision.text.RecognizedLanguage;
import io.flutter.plugin.common.MethodChannel;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class TextRecognizer implements Detector {
  static final TextRecognizer instance = new TextRecognizer();

  private TextRecognizer() {}

  private FirebaseVisionTextRecognizer textRecognizer;
  private Map<String, Object> lastOptions;

  @Override
  public void handleDetection(
      FirebaseVisionImage image, Map<String, Object> options, final MethodChannel.Result result) {

    if (textRecognizer != null && !options.equals(lastOptions)) {
      try {
        textRecognizer.close();
        textRecognizer = null;
      } catch (IOException e) {
        result.error("textRecognizerIOError", e.getLocalizedMessage(), null);
        return;
      }
    }

    if (textRecognizer == null) {
      String recognizerType = (String) options.get("recognizerType");
      switch (recognizerType) {
        case "onDevice":
          textRecognizer = FirebaseVision.getInstance().getOnDeviceTextRecognizer();
          break;
        case "cloud":
          FirebaseVisionCloudTextRecognizerOptions recognizerOptions =
              parseCloudOptions(options, result);
          if (recognizerOptions == null) return;

          textRecognizer = FirebaseVision.getInstance().getCloudTextRecognizer(recognizerOptions);
          break;
        default:
          throw new IllegalArgumentException(
              String.format("No TextRecognizer for type: %s", recognizerType));
      }
      lastOptions = options;
    }

    textRecognizer
        .processImage(image)
        .addOnSuccessListener(
            new OnSuccessListener<FirebaseVisionText>() {
              @Override
              public void onSuccess(FirebaseVisionText firebaseVisionText) {
                Map<String, Object> visionTextData = new HashMap<>();
                visionTextData.put("text", firebaseVisionText.getText());

                List<Map<String, Object>> allBlockData = new ArrayList<>();
                for (FirebaseVisionText.TextBlock block : firebaseVisionText.getTextBlocks()) {
                  Map<String, Object> blockData = new HashMap<>();
                  addData(
                      blockData,
                      block.getBoundingBox(),
                      block.getConfidence(),
                      block.getCornerPoints(),
                      block.getRecognizedLanguages(),
                      block.getText());

                  List<Map<String, Object>> allLineData = new ArrayList<>();
                  for (FirebaseVisionText.Line line : block.getLines()) {
                    Map<String, Object> lineData = new HashMap<>();
                    addData(
                        lineData,
                        line.getBoundingBox(),
                        line.getConfidence(),
                        line.getCornerPoints(),
                        line.getRecognizedLanguages(),
                        line.getText());

                    List<Map<String, Object>> allElementData = new ArrayList<>();
                    for (FirebaseVisionText.Element element : line.getElements()) {
                      Map<String, Object> elementData = new HashMap<>();
                      addData(
                          elementData,
                          element.getBoundingBox(),
                          element.getConfidence(),
                          element.getCornerPoints(),
                          element.getRecognizedLanguages(),
                          element.getText());

                      allElementData.add(elementData);
                    }
                    lineData.put("elements", allElementData);
                    allLineData.add(lineData);
                  }
                  blockData.put("lines", allLineData);
                  allBlockData.add(blockData);
                }

                visionTextData.put("blocks", allBlockData);
                result.success(visionTextData);
              }
            })
        .addOnFailureListener(
            new OnFailureListener() {
              @Override
              public void onFailure(@NonNull Exception exception) {
                result.error("textRecognizerError", exception.getLocalizedMessage(), null);
              }
            });
  }

  private void addData(
      Map<String, Object> addTo,
      Rect boundingBox,
      Float confidence,
      Point[] cornerPoints,
      List<RecognizedLanguage> languages,
      String text) {

    if (boundingBox != null) {
      addTo.put("left", boundingBox.left);
      addTo.put("top", boundingBox.top);
      addTo.put("width", boundingBox.width());
      addTo.put("height", boundingBox.height());
    }

    addTo.put("confidence", confidence == null ? null : (double) confidence);

    List<int[]> points = new ArrayList<>();
    if (cornerPoints != null) {
      for (Point point : cornerPoints) {
        points.add(new int[] {point.x, point.y});
      }
    }
    addTo.put("points", points);

    List<Map<String, Object>> allLanguageData = new ArrayList<>();
    for (RecognizedLanguage language : languages) {
      Map<String, Object> languageData = new HashMap<>();
      languageData.put("languageCode", language.getLanguageCode());
      allLanguageData.add(languageData);
    }
    addTo.put("recognizedLanguages", allLanguageData);

    addTo.put("text", text);
  }

  private FirebaseVisionCloudTextRecognizerOptions parseCloudOptions(
      Map<String, Object> options, MethodChannel.Result result) {
    FirebaseVisionCloudTextRecognizerOptions.Builder builder =
        new FirebaseVisionCloudTextRecognizerOptions.Builder();

    boolean enforceCertFingerprintMatch = (Boolean) options.get("enforceCertFingerprintMatch");
    if (enforceCertFingerprintMatch) builder.enforceCertFingerprintMatch();

    @SuppressWarnings("unchecked")
    List<String> hintedLanguages = (List<String>) options.get("hintedLanguages");
    builder.setLanguageHints(hintedLanguages);

    String modelType = (String) options.get("modelType");
    switch (modelType) {
      case "sparse":
        builder.setModelType(FirebaseVisionCloudTextRecognizerOptions.SPARSE_MODEL);
        break;
      case "dense":
        builder.setModelType(FirebaseVisionCloudTextRecognizerOptions.DENSE_MODEL);
        break;
      default:
        result.error(
            "cloudOptionsError", String.format("No support for model type: %s", modelType), null);
        return null;
    }

    return builder.build();
  }
}
