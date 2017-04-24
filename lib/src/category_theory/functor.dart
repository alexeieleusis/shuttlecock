import 'package:shuttlecock/shuttlecock.dart';

/// A Functor represents a “container” of some sort, along with the ability to
/// apply a function uniformly to every element in the container. For example,
/// a list is a container of elements, and we can apply a function to every
/// element of a list, using map. As another example, a binary tree is also a
/// container of elements, and it’s not hard to come up with a way to
/// recursively apply a function to every element in a tree.
///
/// Another intuition is that a Functor represents some sort of “computational
/// context”. This intuition is generally more useful, but is more difficult
/// to explain, precisely because it is so general. Some examples later should
/// help to clarify the Functor-as-context point of view.
///
/// From https://wiki.haskell.org/Typeclassopedia
// ignore: one_member_abstracts
abstract class Functor<A> {
  /// Transforms the elements in this Functor and returns a new Functor that
  /// contains elements of the same type the provided function returns.
  Functor<B> map<B>(Function1<A, B> f);
}
