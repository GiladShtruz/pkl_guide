import 'package:hive/hive.dart';

import 'element_model.dart';

part 'item_model.g.dart';

@HiveType(typeId: 0)
class ItemModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String category;

  @HiveField(2)
  String originalTitle;

  @HiveField(3)
  String? userTitle;

  @HiveField(4)
  String? originalDetail;

  @HiveField(5)
  String? userDetail;

  @HiveField(6)
  String? originalLink;

  @HiveField(7)
  String? userLink;

  @HiveField(8)
  String? originalClassification;

  @HiveField(9)
  String? userClassification;

  @HiveField(10)
  String? originalEquipment;

  @HiveField(11)
  String? userEquipment;

  @HiveField(13)
  List<String> elementTexts;

  @HiveField(14)
  List<bool> isUserElementList;  // true = user element, false = original element

  @HiveField(15)
  bool isElementsChanged;

  @HiveField(16)
  DateTime? lastAccessed;

  @HiveField(17)
  int clickCount;

  @HiveField(18)
  bool isUserCreated;

  @HiveField(19)
  bool isUserChanged;

  @HiveField(20)
  List<bool> selectedElements;

  ItemModel({
    required this.id,
    required this.category,
    required this.originalTitle,
    this.userTitle,
    this.originalDetail,
    this.userDetail,
    this.originalLink,
    this.userLink,
    this.originalClassification,
    this.userClassification,
    this.originalEquipment,
    this.userEquipment,
    List<ElementModel>? elements,
    this.isElementsChanged = false,
    this.lastAccessed,
    this.clickCount = 0,
    this.isUserCreated = false,
    this.isUserChanged = false,
    List<bool>? selectedElements,
    List<String>? elementTextsParam,
    List<bool>? isUserElementListParam,
  }) : elementTexts = elementTextsParam ?? elements?.map((e) => e.text).toList() ?? [],
        isUserElementList = isUserElementListParam ?? elements?.map((e) => e.isUserElement).toList() ?? [],
        selectedElements = selectedElements ?? List.filled(
          elementTextsParam?.length ?? elements?.length ?? 0,
          false
        );

  // Validation check
  bool get isValidState => elementTexts.length == isUserElementList.length;

  // Build elements list from the two parallel lists
  List<ElementModel> _buildElementsList() {
    assert(isValidState, 'Element lists are out of sync!');
    final result = <ElementModel>[];
    for (int i = 0; i < elementTexts.length; i++) {
      result.add(ElementModel(
        elementTexts[i],
        i < isUserElementList.length ? isUserElementList[i] : false,
      ));
    }
    return result;
  }

  // Main getter for elements - returns a defensive copy
  List<ElementModel> get elements => [..._buildElementsList()];

  // Getter for original elements only
  List<ElementModel> get originalElements =>
      elements.where((e) => !e.isUserElement).toList();

  // Getter for user elements only
  List<ElementModel> get userElements =>
      elements.where((e) => e.isUserElement).toList();

  // Get element at specific index
  ElementModel? getElementAt(int index) {
    if (index >= 0 && index < elementTexts.length && index < isUserElementList.length) {
      return ElementModel(elementTexts[index], isUserElementList[index]);
    }
    return null;
  }

  // Get all elements as string list
  List<String> get strElements => List.from(elementTexts);

  // Get elements text by type
  List<String> getElementsText({bool? isUserElement}) {
    if (isUserElement == null) {
      return strElements;
    }
    final result = <String>[];
    for (int i = 0; i < elementTexts.length; i++) {
      if (i < isUserElementList.length && isUserElementList[i] == isUserElement) {
        result.add(elementTexts[i]);
      }
    }
    return result;
  }

  // Count helpers
  int get userElementCount => isUserElementList.where((type) => type).length;
  int get originalElementCount => isUserElementList.where((type) => !type).length;
  bool get hasUserElements => userElementCount > 0;

  // Getters for current values (user values if exist, otherwise original)
  String get name => userTitle ?? originalTitle;
  String? get detail => userDetail ?? originalDetail;
  String? get link => userLink ?? originalLink;
  String? get classification => userClassification ?? originalClassification;
  String? get equipment => userEquipment ?? originalEquipment;

  // Check if has user modifications
  bool get hasUserModifications =>
      userTitle != null ||
          userDetail != null ||
          userLink != null ||
          userClassification != null ||
          userEquipment != null ||
          hasUserElements;

  // Private method to sync both lists
  void _updateElementLists(List<ElementModel> newElements) {
    final oldLength = elementTexts.length;
    elementTexts = newElements.map((e) => e.text).toList();
    isUserElementList = newElements.map((e) => e.isUserElement).toList();
    // Resize selectedElements to match new length, preserving existing selections where possible
    if (newElements.length > oldLength) {
      selectedElements.addAll(List.filled(newElements.length - oldLength, false));
    } else if (newElements.length < oldLength) {
      selectedElements = selectedElements.sublist(0, newElements.length);
    }
    isElementsChanged = hasUserElements;
    if (isElementsChanged) {
      isUserChanged = true;
    }
    save();
  }

  // Setter for elements
  set itemElements(List<ElementModel> newElements) {
    _updateElementLists(newElements);
  }

  // Method to reorder elements
  void reorderElement(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= elementTexts.length) return;
    if (newIndex < 0 || newIndex > elementTexts.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final text = elementTexts.removeAt(oldIndex);
    final type = isUserElementList.removeAt(oldIndex);
    _ensureSelectedElementsSize();
    final selected = selectedElements.removeAt(oldIndex);

    elementTexts.insert(newIndex, text);
    isUserElementList.insert(newIndex, type);
    selectedElements.insert(newIndex, selected);

    save();
  }

  // Method to swap two elements
  void swapElements(int index1, int index2) {
    if (index1 < 0 || index1 >= elementTexts.length) return;
    if (index2 < 0 || index2 >= elementTexts.length) return;

    final tempText = elementTexts[index1];
    final tempType = isUserElementList[index1];
    _ensureSelectedElementsSize();
    final tempSelected = selectedElements[index1];

    elementTexts[index1] = elementTexts[index2];
    isUserElementList[index1] = isUserElementList[index2];
    selectedElements[index1] = selectedElements[index2];

    elementTexts[index2] = tempText;
    isUserElementList[index2] = tempType;
    selectedElements[index2] = tempSelected;

    save();
  }

  // Method to add element at specific position
  void addElementAt(String elementText, int index, {bool isUserCreated = true}) {
    if (index < 0 || index > elementTexts.length) return;

    elementTexts.insert(index, elementText);
    isUserElementList.insert(index, isUserCreated);
    _ensureSelectedElementsSize();
    selectedElements.insert(index, false);

    if (isUserCreated) {
      isElementsChanged = true;
      isUserChanged = true;
    }
    save();
  }

  // Method to add element to the end
  void addElement(String elementText, {bool isUserCreated = true}) {
    elementTexts.add(elementText);
    isUserElementList.add(isUserCreated);
    _ensureSelectedElementsSize();
    selectedElements.add(false);

    if (isUserCreated) {
      isElementsChanged = true;
      isUserChanged = true;
    }
    save();
  }

  // Method to remove element at index
  void removeElementAt(int index) {
    if (index < 0 || index >= elementTexts.length) return;

    final wasUserElement = isUserElementList[index];

    elementTexts.removeAt(index);
    isUserElementList.removeAt(index);
    _ensureSelectedElementsSize();
    if (index < selectedElements.length) {
      selectedElements.removeAt(index);
    }

    if (wasUserElement && !hasUserElements) {
      isElementsChanged = false;
    }
    _updateUserChangedStatus();
  }

  // Method to remove element by text
  void removeElementByText(String elementText) {
    final index = elementTexts.indexOf(elementText);
    if (index != -1) {
      removeElementAt(index);
    }
  }

  // Method to update element at specific index
  void updateElementAt(int index, String newText, bool isUserElement) {
    if (index < 0 || index >= elementTexts.length) return;

    elementTexts[index] = newText;
    isUserElementList[index] = isUserElement;

    if (isUserElement) {
      isElementsChanged = true;
      isUserChanged = true;
    }
    save();
  }

  // Method to toggle element type (user/original)
  void toggleElementType(int index) {
    if (index < 0 || index >= isUserElementList.length) return;

    isUserElementList[index] = !isUserElementList[index];

    isElementsChanged = hasUserElements;
    _updateUserChangedStatus();
  }

  // Method to find element index by text
  int findElementIndex(String text) {
    return elementTexts.indexOf(text);
  }

  // Method to check if element exists
  bool hasElement(String text) {
    return elementTexts.contains(text);
  }

  // Ensure selectedElements list is synced with elementTexts size
  void _ensureSelectedElementsSize() {
    while (selectedElements.length < elementTexts.length) {
      selectedElements.add(false);
    }
    while (selectedElements.length > elementTexts.length) {
      selectedElements.removeLast();
    }
  }

  // Check if element at index is selected
  bool isElementSelected(int index) {
    _ensureSelectedElementsSize();
    if (index >= 0 && index < selectedElements.length) {
      return selectedElements[index];
    }
    return false;
  }

  // Toggle element selection
  void toggleElementSelection(int index) {
    _ensureSelectedElementsSize();
    if (index >= 0 && index < selectedElements.length) {
      selectedElements[index] = !selectedElements[index];
      save();
    }
  }

  // Set element selection
  void setElementSelected(int index, bool selected) {
    _ensureSelectedElementsSize();
    if (index >= 0 && index < selectedElements.length) {
      selectedElements[index] = selected;
      save();
    }
  }

  // Clear all selections
  void clearAllSelections() {
    selectedElements = List.filled(elementTexts.length, false);
    save();
  }

  // Get count of selected elements
  int get selectedCount => selectedElements.where((s) => s).length;

  // Reset specific field methods
  void resetTitle() {
    userTitle = null;
    _updateUserChangedStatus();
  }

  void resetDetail() {
    userDetail = null;
    _updateUserChangedStatus();
  }

  void resetLink() {
    userLink = null;
    _updateUserChangedStatus();
  }

  void resetClassification() {
    userClassification = null;
    _updateUserChangedStatus();
  }

  void resetEquipment() {
    userEquipment = null;
    _updateUserChangedStatus();
  }

  void resetElements() {
    // Remove only user elements
    for (int i = isUserElementList.length - 1; i >= 0; i--) {
      if (isUserElementList[i]) {  // if it's a user element
        elementTexts.removeAt(i);
        isUserElementList.removeAt(i);
      }
    }
    isElementsChanged = false;
    _updateUserChangedStatus();
  }

  void resetAll() {
    userTitle = null;
    userDetail = null;
    userLink = null;
    userClassification = null;
    userEquipment = null;
    resetElements();
    isUserChanged = false;
    save();
  }

  // Update user changed status based on modifications
  void _updateUserChangedStatus() {
    isUserChanged = hasUserModifications;
    save();
  }

  // Method to update title and mark as changed
  void updateTitle(String newTitle) {
    userTitle = newTitle;
    isUserChanged = true;
    save();
  }

  // Method to update detail and mark as changed
  void updateDetail(String? newDetail) {
    userDetail = newDetail;
    isUserChanged = true;
    save();
  }

  // Method to update link and mark as changed
  void updateLink(String? newLink) {
    userLink = newLink;
    isUserChanged = true;
    save();
  }

  // Method to update classification and mark as changed
  void updateClassification(String? newClassification) {
    userClassification = newClassification;
    isUserChanged = true;
    save();
  }

  // Method to update equipment and mark as changed
  void updateEquipment(String? newEquipment) {
    userEquipment = newEquipment;
    isUserChanged = true;
    save();
  }



  Map<String, dynamic> toJson() {
    // Convert elements to the correct format
    final elementsList = <Map<String, dynamic>>[];
    for (int i = 0; i < elementTexts.length; i++) {
      elementsList.add({
        'element': elementTexts[i],
        'isUserElement': i < isUserElementList.length ? isUserElementList[i] : false,
      });
    }

    return {
      'id': id,
      'category': category,
      'originalTitle': originalTitle,
      'userTitle': userTitle,
      'originalDetail': originalDetail,
      'userDetail': userDetail,
      'originalLink': originalLink,
      'userLink': userLink,
      'originalClassification': originalClassification,
      'userClassification': userClassification,
      'originalEquipment': originalEquipment,
      'userEquipment': userEquipment,
      'elements': elementsList,
      'isElementsChanged': isElementsChanged,
      'lastAccessed': lastAccessed?.toIso8601String(),
      'clickCount': clickCount,
      'isUserCreated': isUserCreated,
      'isUserChanged': isUserChanged,
    };
  }
}