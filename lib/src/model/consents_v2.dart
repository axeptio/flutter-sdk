class ConsentsV2 {
  bool analyticsStorage;
  bool adStorage;
  bool adUserData;
  bool adPersonalization;

  ConsentsV2(this.analyticsStorage, this.adStorage, this.adUserData,
      this.adPersonalization);

  ConsentsV2.fromDictionary(dynamic dictionary)
      : analyticsStorage = dictionary["analyticsStorage"],
        adStorage = dictionary["adStorage"],
        adUserData = dictionary["adUserData"],
        adPersonalization = dictionary["adPersonalization"];
}
